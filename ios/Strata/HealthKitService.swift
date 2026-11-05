import HealthKit
import StrataCore

struct HealthAccessSummary: Equatable {
    var isAvailable: Bool
    var workoutAccess: String
    var stepsAccess: String

    static let checking = HealthAccessSummary(
        isAvailable: true,
        workoutAccess: "Checking…",
        stepsAccess: "Checking…"
    )
}

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

    func startStrengthWatch() async -> Bool {
        guard available else { return false }
        _ = bridge
        let cfg = HKWorkoutConfiguration()
        cfg.activityType = .traditionalStrengthTraining
        cfg.locationType = .indoor
        do {
            try await store.startWatchApp(toHandle: cfg)
            return true
        } catch {
            return false
        }
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

    /// A user-visible check of the Health permissions Strata currently uses.
    /// HealthKit intentionally does not reveal denied read permission, so a nil step result is
    /// reported as no readable data rather than incorrectly claiming access was denied.
    func accessSummary(requestAuthorization: Bool) async -> HealthAccessSummary {
        guard available else {
            return HealthAccessSummary(
                isAvailable: false,
                workoutAccess: "Unavailable",
                stepsAccess: "Unavailable"
            )
        }

        if requestAuthorization {
            _ = await authorize()
        }

        let workoutAccess: String
        switch store.authorizationStatus(for: HKObjectType.workoutType()) {
        case .sharingAuthorized:
            workoutAccess = "Allowed"
        case .sharingDenied:
            workoutAccess = "Not allowed"
        case .notDetermined:
            workoutAccess = "Not requested"
        @unknown default:
            workoutAccess = "Unknown"
        }

        let todaySteps = await steps(on: Date())
        let stepsAccess = todaySteps.map { "\($0.formatted()) today" } ?? "No readable data today"
        return HealthAccessSummary(
            isAvailable: true,
            workoutAccess: workoutAccess,
            stepsAccess: stepsAccess
        )
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

    /// Daily totals over a date range. `HKStatisticsCollectionQuery` lets HealthKit merge
    /// overlapping phone/watch sources instead of Strata adding raw samples itself.
    func dailySteps(from start: Date, through end: Date) async -> [String: Int]? {
        guard available else { return nil }
        let calendar = Calendar.current
        let from = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        guard let to = calendar.date(byAdding: .day, value: 1, to: endDay) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)
        var interval = DateComponents()
        interval.day = 1

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: from,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, collection, error in
                guard error == nil, let collection else {
                    continuation.resume(returning: nil)
                    return
                }
                let formatter = DateFormatter()
                formatter.calendar = calendar
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = calendar.timeZone
                formatter.dateFormat = "yyyy-MM-dd"
                var totals: [String: Int] = [:]
                collection.enumerateStatistics(from: from, to: endDay) { statistics, _ in
                    if let quantity = statistics.sumQuantity() {
                        totals[formatter.string(from: statistics.startDate)] = Int(quantity.doubleValue(for: .count()))
                    }
                }
                continuation.resume(returning: totals)
            }
            store.execute(query)
        }
    }
}
