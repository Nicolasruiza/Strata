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

/// One heart-rate point on a session chart: minutes since the start, average bpm of that slice.
struct HRPoint: Equatable { let minute: Double; let bpm: Double }

/// What Apple Health knows about one workout: the heart-rate curve, distance and climb.
struct WorkoutDetail: Equatable {
    let start: Date
    let minutes: Double
    let hr: [HRPoint]
    let avgHR: Double?
    let maxHR: Double?
    let distanceKm: Double?
    let ascendedM: Double?
}

/// A whole day from Health: steps and average heart rate per hour, plus distance and floors.
struct DaySeries: Equatable {
    let stepsByHour: [Double]
    let hrByHour: [Double?]
    let distanceKm: Double?
    let flights: Double?
}

/// One VO2 max estimate (mL/kg/min) from Apple Health, usually made by the Watch.
struct Vo2Reading: Equatable {
    let date: Date
    let value: Double
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
    private let vo2Type = HKQuantityType(.vo2Max)
    private let distanceTypes = [HKQuantityType(.distanceWalkingRunning), HKQuantityType(.distanceCycling)]
    private let flightsType = HKQuantityType(.flightsClimbed)

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
            try await store.requestAuthorization(toShare: [HKObjectType.workoutType(), hrType], read: Set<HKObjectType>([stepType, sleepType, vo2Type, hrType, flightsType, HKObjectType.workoutType()] + distanceTypes))
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

    /// VO2 max estimates in a date range, oldest first. Nil when Health has nothing readable.
    func vo2Readings(from start: Date, through end: Date) async -> [Vo2Reading]? {
        guard available else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        let unit = HKUnit(from: "ml/(kg*min)")
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: vo2Type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: sort) { _, samples, error in
                guard error == nil, let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: samples.map { Vo2Reading(date: $0.startDate, value: $0.quantity.doubleValue(for: unit)) })
            }
            store.execute(query)
        }
    }

    // MARK: session / day detail

    private func civilDay(_ ymd: String) -> Date? {
        let f = DateFormatter()
        f.calendar = Calendar.current; f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"
        return f.date(from: ymd)
    }

    private func samples(_ type: HKSampleType, _ predicate: NSPredicate, ascending: Bool = true) async -> [HKSample]? {
        await withCheckedContinuation { continuation in
            let sort = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: ascending)]
            let q = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: sort) { _, result, error in
                continuation.resume(returning: error == nil ? result : nil)
            }
            store.execute(q)
        }
    }

    private func total(_ type: HKQuantityType, unit: HKUnit, from: Date, to: Date) async -> Double? {
        await withCheckedContinuation { continuation in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: HKQuery.predicateForSamples(withStart: from, end: to), options: .cumulativeSum) { _, r, _ in
                continuation.resume(returning: r?.sumQuantity()?.doubleValue(for: unit))
            }
            store.execute(q)
        }
    }

    /// The Health workout on `day` whose length is closest to `minutes` (Strata's own saved
    /// workouts are included: they carry the heart-rate samples), with its heart-rate curve.
    func workoutDetail(on ymd: String, minutes: Double?) async -> WorkoutDetail? {
        guard available, let from = civilDay(ymd), let to = Calendar.current.date(byAdding: .day, value: 1, to: from) else { return nil }
        guard let found = await samples(HKObjectType.workoutType(), HKQuery.predicateForSamples(withStart: from, end: to)) as? [HKWorkout],
              !found.isEmpty else { return nil }
        let w = found.min { abs($0.duration / 60 - (minutes ?? $0.duration / 60)) < abs($1.duration / 60 - (minutes ?? $1.duration / 60)) } ?? found[0]

        let bpm = HKUnit.count().unitDivided(by: .minute())
        let hrSamples = (await samples(hrType, HKQuery.predicateForSamples(withStart: w.startDate, end: w.endDate)) as? [HKQuantitySample]) ?? []
        let values = hrSamples.map { $0.quantity.doubleValue(for: bpm) }
        let buckets = 24, length = max(1, w.duration)
        var sums = [Double](repeating: 0, count: buckets), counts = [Double](repeating: 0, count: buckets)
        for sample in hrSamples {
            let i = min(buckets - 1, max(0, Int(sample.startDate.timeIntervalSince(w.startDate) / length * Double(buckets))))
            sums[i] += sample.quantity.doubleValue(for: bpm); counts[i] += 1
        }
        let curve = (0..<buckets).compactMap { i -> HRPoint? in
            counts[i] > 0 ? HRPoint(minute: (Double(i) + 0.5) / Double(buckets) * w.duration / 60, bpm: sums[i] / counts[i]) : nil
        }

        var km: Double?
        for type in distanceTypes {
            if let m = w.statistics(for: type)?.sumQuantity()?.doubleValue(for: .meter()), m > 0 { km = m / 1000; break }
        }
        let up = (w.metadata?[HKMetadataKeyElevationAscended] as? HKQuantity)?.doubleValue(for: .meter())
        return WorkoutDetail(start: w.startDate, minutes: w.duration / 60, hr: curve,
                             avgHR: values.isEmpty ? nil : values.reduce(0, +) / Double(values.count), maxHR: values.max(),
                             distanceKm: km, ascendedM: up)
    }

    /// Hourly steps and heart rate for a civil day, with the day's distance and floors climbed.
    func daySeries(on ymd: String) async -> DaySeries? {
        guard available, let from = civilDay(ymd), let to = Calendar.current.date(byAdding: .day, value: 1, to: from) else { return nil }
        var hour = DateComponents(); hour.hour = 1
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)
        let bpm = HKUnit.count().unitDivided(by: .minute())

        func hourly(_ type: HKQuantityType, _ options: HKStatisticsOptions, _ value: @escaping (HKStatistics) -> Double?) async -> [Double?] {
            await withCheckedContinuation { continuation in
                let q = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: predicate, options: options, anchorDate: from, intervalComponents: hour)
                q.initialResultsHandler = { _, collection, _ in
                    var out = [Double?](repeating: nil, count: 24)
                    collection?.enumerateStatistics(from: from, to: to) { stat, _ in
                        let h = Calendar.current.component(.hour, from: stat.startDate)
                        if h < 24 { out[h] = value(stat) }
                    }
                    continuation.resume(returning: out)
                }
                store.execute(q)
            }
        }
        let steps = await hourly(stepType, .cumulativeSum) { $0.sumQuantity()?.doubleValue(for: .count()) }
        let rates = await hourly(hrType, .discreteAverage) { $0.averageQuantity()?.doubleValue(for: bpm) }
        var meters = 0.0
        for type in distanceTypes { meters += await total(type, unit: .meter(), from: from, to: to) ?? 0 }
        let flights = await total(flightsType, unit: .count(), from: from, to: to)
        return DaySeries(stepsByHour: steps.map { $0 ?? 0 }, hrByHour: rates,
                         distanceKm: meters > 0 ? meters / 1000 : nil, flights: (flights ?? 0) > 0 ? flights : nil)
    }
}
