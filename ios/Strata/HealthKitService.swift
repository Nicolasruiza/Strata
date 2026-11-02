import HealthKit
import StrataCore

/// workout.js `Health` on iPhone, implemented for real with HealthKit. Both calls return what
/// actually happened: `saved` is true only when the workout was written to Apple Health.
/// Only the types Strata uses are requested: workouts and heart rate (write), steps (read).
final class HealthKitService: HealthService {
    let store = HKHealthStore()
    private(set) lazy var bridge = WatchBridge(store: store)
    private let hrType = HKQuantityType(.heartRate)
    private let stepType = HKQuantityType(.stepCount)

    var available: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Launches the Strata watch app with this workout (`HKHealthStore.startWatchApp`); the watch
    /// then starts its session and mirrors it back. Returns whether the watch accepted the start.
    func startWatch(_ cfg: WatchStartConfig) async -> Bool {
        guard available else { return false }
        _ = bridge
        do {
            try await store.startWatchApp(toHandle: configuration(act: cfg.activity, type: nil))
            return true
        } catch { return false }
    }

    private func configuration(act: String, type: String?) -> HKWorkoutConfiguration {
        let cfg = HKWorkoutConfiguration()
        let out = Catalog.shared.cardioActs[act]?.out == true
        switch act {
        case "bike_out", "bike_in": cfg.activityType = .cycling
        case "walk": cfg.activityType = .walking
        case "elliptical": cfg.activityType = .elliptical
        case "row": cfg.activityType = .rowing
        case "swim": cfg.activityType = .swimming; cfg.swimmingLocationType = .pool
        default: cfg.activityType = type == "4x4" ? .running : .walking
        }
        if act != "elliptical" && act != "swim" { cfg.locationType = out ? .outdoor : .indoor }
        return cfg
    }

    private func authorize() async -> Bool {
        guard available else { return false }
        do {
            try await store.requestAuthorization(toShare: [HKObjectType.workoutType(), hrType], read: [stepType])
            return store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
        } catch { return false }
    }

    func saveWorkout(_ entry: HealthPayload) async -> Bool {
        // With the watch session running, the watch saved the workout: report its real answer.
        if let saved = await bridge.endAndWaitForSave() { return saved }
        guard await authorize() else { return false }
        let cfg = configuration(act: entry.act, type: entry.type)
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
