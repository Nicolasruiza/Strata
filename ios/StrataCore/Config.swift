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

    /// VO2 max norms (mL/kg/min), Cooper Institute percentiles as printed in Garmin's standard
    /// ratings: the value needed to *reach* Fair (40th percentile), Good (60th), Excellent (80th)
    /// and Superior (95th). Below Fair is Poor. Age bands start at 20, 30, ... 70.
    public enum Vo2Norms {
        public static let ratings = ["Poor", "Fair", "Good", "Excellent", "Superior"]
        public static let male: [[Double]] = [
            [41.7, 45.4, 51.1, 55.4], [40.5, 44.0, 48.3, 54.0], [38.5, 42.4, 46.4, 52.5],
            [35.6, 39.2, 43.4, 48.9], [32.3, 35.5, 39.5, 45.7], [29.4, 32.3, 36.7, 42.1]]
        public static let female: [[Double]] = [
            [36.1, 39.5, 43.9, 49.6], [34.4, 37.8, 42.4, 47.4], [33.0, 36.3, 39.7, 45.3],
            [30.1, 33.0, 36.7, 41.1], [27.5, 30.0, 33.0, 37.8], [25.9, 28.1, 30.9, 36.7]]
    }

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
        /// VO2 max: compare the last `vo2RecentDays` with the `vo2PriorDays` before that; a drop of
        /// at least `vo2DropMin` mL/kg/min is worth saying out loud.
        public static let vo2RecentDays = 30
        public static let vo2PriorDays = 60
        public static let vo2DropMin = 1.0
        /// The Move card has a fixed size: a title on one line, a body on up to three. Every message must fit.
        public static let maxTitleChars = 30
        public static let maxBodyChars = 100
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

extension Config {
    /// Daily Mobility: a routine from a home exercise handout. It sits beside the rings, never inside them:
    /// nothing here changes ring targets or streaks, and a missed session is never flagged.
    public enum Mobility {
        public struct Session: Equatable, Identifiable { public let id: String; public let label: String }
        public struct Exercise: Equatable, Identifiable {
            public let id: String
            public let name: String
            public let category: String
            public let purpose: String
            public let sets: Int
            public let reps: Int
            /// Seconds held on every rep, nil when the handout gives no timed hold.
            public let holdSeconds: Int?
            public let equipment: String?
            public let steps: [String]
            public let cue: String
            public let startImage: String
            public let finishImage: String
            public var prescription: String {
                "\(sets) set\(sets > 1 ? "s" : "") × \(reps) rep\(reps > 1 ? "s" : "")" + (holdSeconds.map { " · hold \($0) s each" } ?? "")
            }
        }

        /// Morning and evening each repeat the same exercises.
        public static let sessions = [Session(id: "morning", label: "Morning"), Session(id: "evening", label: "Evening")]

        public static let exercises: [Exercise] = [
            Exercise(id: "glide", name: "Sciatic nerve glide", category: "Nerve mobility",
                     purpose: "Controlled knee and ankle movement that lets the sciatic nerve glide as the leg moves.",
                     sets: 4, reps: 10, holdSeconds: nil, equipment: nil,
                     steps: ["Lie on your back. Support the working leg with both hands behind the thigh and bring the knee just above the hip.",
                             "Keep the other leg straight, flat and still.",
                             "Straighten the working knee until you first feel tension, then draw your toes toward your shin.",
                             "Relax the foot, bend the knee back to the start and repeat."],
                     cue: "Keep the other leg flat. Stop straightening at the first point of tension.",
                     startImage: "mob_glide_start", finishImage: "mob_glide_finish"),
            Exercise(id: "pressup", name: "Prone press-up", category: "Lower-back mobility",
                     purpose: "Moves the lower back into extension as you lift your chest, supported on your forearms.",
                     sets: 2, reps: 10, holdSeconds: 10, equipment: nil,
                     steps: ["Lie face down with elbows bent and forearms on the mat.",
                             "Lift your chest and prop yourself on your elbows and forearms.",
                             "Keep your hips down and your head in line with your upper body.",
                             "Hold, then lower back to the start."],
                     cue: "Stay on your forearms the whole time, elbows bent.",
                     startImage: "mob_press_start", finishImage: "mob_press_finish"),
            Exercise(id: "itband", name: "IT band stretch with belt", category: "Outer-thigh flexibility",
                     purpose: "A belt guides the raised leg across the body for a gentle stretch along the outside of the thigh.",
                     sets: 1, reps: 5, holdSeconds: 10, equipment: "Belt or stretching strap",
                     steps: ["Lie on your back and loop the belt around the working foot.",
                             "Raise that leg with the knee straight.",
                             "Use the belt to guide the leg gently across the midline of your body until you feel a stretch along the outer thigh.",
                             "Hold, then release and return to the start."],
                     cue: "Keep the raised knee straight and make a small, controlled movement across the body.",
                     startImage: "mob_belt_start", finishImage: "mob_belt_finish"),
        ]
        public static let safetyNote = "Move gently. If pain increases or spreads, stop and check with your clinician."
    }
}
