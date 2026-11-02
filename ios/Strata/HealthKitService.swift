import HealthKit
import StrataCore

/// workout.js `Health` on iPhone, implemented for real with HealthKit. Both calls return what
/// actually happened: `saved` is true only when the workout was written to Apple Health.
/// Only the types Strata uses are requested: workouts and heart rate (write), steps (read).
final class HealthKitService: HealthService {
    private let store = HKHealthStore()
    private let hrType = HKQuantityType(.heartRate)
    private let stepType = HKQuantityType(.stepCount)

    var available: Bool { HKHealthStore.isHealthDataAvailable() }

    /// The Watch is started by the watch phase; the phone has nothing to start on its own.
    func startWatch(_ cfg: WatchStartConfig) async -> Bool { false }

    private func authorize() async -> Bool {
        guard available else { return false }
        do {
            try await store.requestAuthorization(toShare: [HKObjectType.workoutType(), hrType], read: [stepType])
            return store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
        } catch { return false }
    }

    func saveWorkout(_ entry: HealthPayload) async -> Bool {
        guard await authorize() else { return false }
        let cfg = HKWorkoutConfiguration()
        let out = Catalog.shared.cardioActs[entry.act]?.out == true
        switch entry.act {
        case "bike_out", "bike_in": cfg.activityType = .cycling
        case "walk": cfg.activityType = .walking
        case "elliptical": cfg.activityType = .elliptical
        case "row": cfg.activityType = .rowing
        case "swim": cfg.activityType = .swimming; cfg.swimmingLocationType = .pool
        default: cfg.activityType = entry.type == "4x4" ? .running : .walking
        }
        if entry.act != "elliptical" && entry.act != "swim" { cfg.locationType = out ? .outdoor : .indoor }
        let start = Date(timeIntervalSince1970: entry.start / 1000), end = Date(timeIntervalSince1970: entry.end / 1000)
        let builder = HKWorkoutBuilder(healthStore: store, configuration: cfg, device: .local())
        do {
            try await builder.beginCollection(at: start)
            let unit = HKUnit.count().unitDivided(by: .minute())
            let hr: [HKQuantitySample] = entry.samples.compactMap { s in
                guard let v = s.hr else { return nil }
                let d = start.addingTimeInterval(s.t)
                return HKQuantitySample(type: hrType, quantity: HKQuantity(unit: unit, doubleValue: v), start: d, end: d)
            }
            if !hr.isEmpty { try await builder.addSamples(hr) }
            try await builder.endCollection(at: end)
            return try await builder.finishWorkout() != nil
        } catch { return false }
    }

    /// Steps for a civil day, or nil when Health has no readable data (the field stays manual).
    func steps(on day: Date) async -> Int? {
        guard available else { return nil }
        let cal = Calendar.current
        let from = cal.startOfDay(for: day), to = cal.date(byAdding: .day, value: 1, to: from) ?? day
        let pred = HKQuery.predicateForSamples(withStart: from, end: to)
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: pred, options: .cumulativeSum) { _, r, _ in
                let n = r?.sumQuantity()?.doubleValue(for: .count())
                cont.resume(returning: n.map { Int($0) })
            }
            store.execute(q)
        }
    }
}
