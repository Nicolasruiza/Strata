import Foundation

/// Every number the logic uses. `WorkoutConfig` mirrors `WCFG` in workout.js field for
/// field (the golden test compares them); the rest are the constants core.js / app.js
/// had inline. No magic numbers in views or logic: they come from here.
public struct WorkoutConfig: Codable, Equatable {
    public var countdownSec: Int
    public var sampleEverySec: Double
    public var maxSampleGapSec: Double
    public var zoneTops: [Double]
    public var elevNoiseM: Double
    public var elevMaxAccuracyM: Double
    public var intervalCreditFrac: Double
    public var shortCardioMin: Double
    public var busyMin: Double
    public var warmupSteps: [[Double]]
    public var emptyBarReps: Int
    public var fallbackAct: [String: String]
    public var guide: [String: String]
}

public enum Config {
    public static let workout = WorkoutConfig(
        countdownSec: 3,
        sampleEverySec: 5,
        maxSampleGapSec: 15,
        zoneTops: [0.6, 0.7, 0.8, 0.9],
        elevNoiseM: 1,
        elevMaxAccuracyM: 20,
        intervalCreditFrac: 0.75,
        shortCardioMin: 20,
        busyMin: 3,
        warmupSteps: [[0.5, 6], [0.7, 3]],
        emptyBarReps: 8,
        fallbackAct: ["4x4": "treadmill", "z2": "treadmill", "walk": "walk", "office": "walk", "other": "elliptical"],
        guide: [
            "z2": "45–60 min at a conversational pace",
            "walk": "45–90 min, easy pace",
            "office": "Counts toward your steps goal",
            "other": "Easy cardio block before or after your lift",
        ]
    )

    /// core.js `MIN_PER_LIFT`: measured, ~12 minutes per lift including setup and rest.
    public static let minutesPerLift = 12.0
    /// Sets in a normal prescription (`ex.sets||3`) and on a lighter day.
    public static let defaultSets = 3
    public static let lighterDaySets = 2
    /// Lighter day: 85% of the weight, rounded down to a multiple of `weightStep`.
    public static let lighterDayWeightFrac = 0.85
    public static let weightStep = 5.0

    /// Rest between sets, seconds (`restFor`, +30 s button).
    public enum Rest {
        public static let keyLift = 120.0
        public static let optionalBlock = 60.0
        public static let standard = 90.0
        public static let extend = 30.0
    }

    /// Heart-rate estimate (`rcHR`): Tanaka, valid for ages 14–99.
    public enum Heart {
        public static let maxIntercept = 208.0
        public static let maxPerYear = 0.7
        public static let minAge = 14.0
        public static let maxAge = 99.0
        public static let z2: [Double] = [0.6, 0.7]
        public static let hard: [Double] = [0.85, 0.95]
    }

    /// 4×4 structure (`rcPhases`, `rcMinutes`) and the ramp-up rule (`rcDefaultIntervals`).
    public enum Intervals {
        public static let warmupSec = 600
        public static let hardSec = 240
        public static let recoverSec = 180
        public static let cooldownSec = 300
        public static let rampSessions = 3
        public static let rampCount = 3
        public static let fullCount = 4
        public static let displayFallbackCount = 4     // `L.n||4`
    }

    /// Weekly ring targets that are not derived from the plan.
    public static let boneDaysPerWeek = 2

    /// Thresholds for the Move-tab insight card. Not in the web app: these are new.
    public enum Insights {
        /// Muscle is built during sleep: under this average is "short".
        public static let sleepMinHours = 7.0
        /// Nights/days of data needed before a health insight is trusted.
        public static let minSleepNights = 3
        public static let minStepDays = 3
        /// Daily steps where the longevity benefit levels off (roughly 7-8k).
        public static let stepsMinDaily = 7_000.0
        /// A ring left open this many completed weeks in a row triggers an insight.
        public static let ringMissedWeeks = 2
    }
    public static let landingsPerJumpDay = 45
    public static let landingsHomeLegs = 30

    /// Settings / input limits.
    public static let defaultAge = 40.0
    public static let waistRangeCm = (min: 40.0, max: 200.0)
    public static let officeSteps = 10_000

    /// Profile defaults by gender (`newProfile`, `setGender`).
    public enum Profiles {
        public static let maleBodyweight = 194.0
        public static let femaleBodyweight = 132.0
        public static let maleExp = "trained"
        public static let femaleExp = "new"
    }

    /// Zone labels and colours (`ZNAME`, `ZCOL`); index 0 is unused, as on the web.
    public static let zoneNames = ["", "Warm-up", "Easy", "Endurance", "Threshold", "Max"]
    public static let zoneColors = ["", "#6E7385", "#8A8FA0", "#FF6B4A", "#C9553B", "#8E3B2A"]

    /// Copy for states that depend on the sensor / Health result. Chosen only from what
    /// actually happened (`saveWorkout()` result, watch reachability, location state).
    public enum Copy {
        public static let noHeartRateNoWatchYet = "No heart-rate source yet. Apple Watch support is on the way."
        public static let chipWatchUnsupported = "Apple Watch: not yet supported"
        public static let footerSavedInStrata = "Saved in Strata"

        public static let noHeartRateWatchUnreachable = "No heart rate. Open Strata on your Apple Watch."
        public static let chipWatchNotConnected = "Apple Watch not connected"
        public static let footerNotSavedToHealth = "Saved in Strata · Not saved to Apple Health"

        public static let chipWatchConnected = "Apple Watch connected"
        public static let footerSavedToHealth = "Saved to Apple Health"

        public static let addAgeForZones = "Add your age in Settings to see zones"

        public static let waitingForGPS = "Waiting for GPS"
        public static let noGPS = "No GPS"
        public static let preciseLocationOff = "Precise location off"
    }
}
