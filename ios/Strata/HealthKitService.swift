import HealthKit
import StrataCore

struct HealthAccessSummary: Equatable {
    var isAvailable: Bool
    var workoutAccess: String
    var stepsAccess: String
    var sleepAccess: String
    var workoutsRead: String

    static let checking = HealthAccessSummary(
        isAvailable: true,
        workoutAccess: "Checking…",
        stepsAccess: "Checking…",
        sleepAccess: "Checking…",
        workoutsRead: "Checking…"
    )
}

/// One workout Apple Health has for a day (recorded on the Watch or by another app).
struct HealthWorkoutRow: Identifiable, Equatable {
    let id: UUID
    let name: String
    let start: Date
    let minutes: Double
    let isStrength: Bool
}

/// workout.js `Health` on iPhone, implemented for real with HealthKit. Both calls return what
/// actually happened: `saved` is true only when the workout was written to Apple Health.
/// Only the types Strata uses are requested: workouts and heart rate (write), steps, sleep and workouts (read).
final class HealthKitService: HealthService {
    let store = HKHealthStore()
    private(set) lazy var bridge = WatchBridge(store: store)
    private let hrType = HKQuantityType(.heartRate)
    private let stepType = HKQuantityType(.stepCount)
    private let sleepType = HKCategoryType(.sleepAnalysis)

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
            try await store.requestAuthorization(toShare: [HKObjectType.workoutType(), hrType], read: [stepType, sleepType, HKObjectType.workoutType()])
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
                stepsAccess: "Unavailable",
                sleepAccess: "Unavailable",
                workoutsRead: "Unavailable"
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
        let lastNight = await dailySleep(from: Date().addingTimeInterval(-3 * 86_400), through: Date())?
            .sorted { $0.key < $1.key }.last
        let sleepAccess = lastNight.map { "\(String(format: "%.1f", $0.value)) h last night" } ?? "No readable data"
        let minutes = await dailyWorkoutMinutes(from: Date().addingTimeInterval(-56 * 86_400), through: Date())?.values.reduce(0, +) ?? 0
        let workoutsRead = minutes > 0 ? "\(Int(minutes.rounded())) min in 8 wks" : "No readable data"
        return HealthAccessSummary(
            isAvailable: true,
            workoutAccess: workoutAccess,
            stepsAccess: stepsAccess,
            sleepAccess: sleepAccess,
            workoutsRead: workoutsRead
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

    /// Hours asleep per night, keyed by the day the sleep ended (the morning you woke up).
    /// Overlapping samples from several sources (watch, phone, apps) are merged so nothing is
    /// counted twice. Nil when Health has nothing readable.
    func dailySleep(from start: Date, through end: Date) async -> [String: Double]? {
        guard available else { return nil }
        let calendar = Calendar.current
        let from = calendar.startOfDay(for: start)
        guard let to = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: end)) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)
        let asleep: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue
        ]
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                guard error == nil, let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }
                let spans = samples.filter { asleep.contains($0.value) }
                    .map { ($0.startDate, $0.endDate) }.sorted { $0.0 < $1.0 }
                var merged: [(Date, Date)] = []
                for span in spans {
                    if let last = merged.last, span.0 <= last.1 { merged[merged.count - 1].1 = max(last.1, span.1) }
                    else { merged.append(span) }
                }
                let formatter = DateFormatter()
                formatter.calendar = calendar
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = calendar.timeZone
                formatter.dateFormat = "yyyy-MM-dd"
                var hours: [String: Double] = [:]
                for span in merged { hours[formatter.string(from: span.1), default: 0] += span.1.timeIntervalSince(span.0) / 3600 }
                continuation.resume(returning: hours)
            }
            store.execute(query)
        }
    }

    /// Minutes of cardio workouts per day from Apple Health (Fitness, other apps, third-party watches).
    /// Strength workouts are skipped, and so is anything Strata itself saved: those minutes are
    /// already in Strata's own log, so counting them again would double them.
    func dailyWorkoutMinutes(from start: Date, through end: Date) async -> [String: Double]? {
        guard available else { return nil }
        let calendar = Calendar.current
        let from = calendar.startOfDay(for: start)
        guard let to = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: end)) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                guard error == nil, let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: nil)
                    return
                }
                let formatter = DateFormatter()
                formatter.calendar = calendar
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = calendar.timeZone
                formatter.dateFormat = "yyyy-MM-dd"
                var minutes: [String: Double] = [:]
                for workout in workouts {
                    if workout.workoutActivityType == .traditionalStrengthTraining || workout.workoutActivityType == .functionalStrengthTraining { continue }
                    if workout.sourceRevision.source.bundleIdentifier.hasPrefix("net.nicolasruiza.strata") { continue }
                    minutes[formatter.string(from: workout.startDate), default: 0] += workout.duration / 60
                }
                continuation.resume(returning: minutes)
            }
            store.execute(query)
        }
    }

    /// Workouts Apple Health has for a civil day, newest first. Anything Strata saved itself is
    /// left out because Strata already lists it from its own log.
    func workouts(on day: Date) async -> [HealthWorkoutRow]? {
        guard available else { return nil }
        let calendar = Calendar.current
        let from = calendar.startOfDay(for: day)
        guard let to = calendar.date(byAdding: .day, value: 1, to: from) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: sort) { _, samples, error in
                guard error == nil, let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: nil)
                    return
                }
                let rows = workouts
                    .filter { !$0.sourceRevision.source.bundleIdentifier.hasPrefix("net.nicolasruiza.strata") }
                    .map { w in
                        HealthWorkoutRow(id: w.uuid, name: Self.workoutName(w.workoutActivityType), start: w.startDate,
                                         minutes: w.duration / 60,
                                         isStrength: w.workoutActivityType == .traditionalStrengthTraining || w.workoutActivityType == .functionalStrengthTraining)
                    }
                continuation.resume(returning: rows)
            }
            store.execute(query)
        }
    }

    private static func workoutName(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: return "Walk"
        case .running: return "Run"
        case .cycling: return "Bike"
        case .hiking: return "Hike"
        case .elliptical: return "Elliptical"
        case .rowing: return "Row"
        case .swimming: return "Swim"
        case .traditionalStrengthTraining, .functionalStrengthTraining: return "Strength"
        case .highIntensityIntervalTraining: return "HIIT"
        case .yoga: return "Yoga"
        case .stairClimbing: return "Stairs"
        default: return "Workout"
        }
    }
}
