import Foundation

public enum WatchWorkoutMode: String, Codable, Equatable, Sendable { case idle, strength, cardio }

public struct WatchPlanSnapshot: Codable, Equatable, Sendable {
    public var name: String
    public var detail: String
    public init(name: String, detail: String) { self.name = name; self.detail = detail }
}

public struct WatchExerciseSnapshot: Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var imageName: String?
    public var setIndex: Int
    public var setCount: Int
    public var targetReps: Double
    public var load: Double
    public var loadUnit: String
    public var loadIncrement: Double
    public var lastSummary: String?
    public var durationSeconds: Int?
    public var restSeconds: Int

    public init(id: String, name: String, imageName: String?, setIndex: Int, setCount: Int,
                targetReps: Double, load: Double, loadUnit: String, loadIncrement: Double,
                lastSummary: String?, durationSeconds: Int?, restSeconds: Int) {
        self.id = id; self.name = name; self.imageName = imageName; self.setIndex = setIndex
        self.setCount = setCount; self.targetReps = targetReps; self.load = load
        self.loadUnit = loadUnit; self.loadIncrement = loadIncrement; self.lastSummary = lastSummary
        self.durationSeconds = durationSeconds; self.restSeconds = restSeconds
    }
}

public struct WatchRestSnapshot: Codable, Equatable, Sendable {
    public var endsAt: Date
    public var nextName: String?
    public var nextTarget: String?
    public init(endsAt: Date, nextName: String?, nextTarget: String?) {
        self.endsAt = endsAt; self.nextName = nextName; self.nextTarget = nextTarget
    }
}

public struct WatchCardioSnapshot: Codable, Equatable, Sendable {
    public var activityName: String
    public var startedAt: Date
    public var zoneName: String?
    public var zoneIndex: Int?
    public var phaseName: String?
    public var phaseIndex: Int?
    public var phaseCount: Int?
    public var phaseEndsAt: Date?
    public init(activityName: String, startedAt: Date, zoneName: String? = nil, zoneIndex: Int? = nil,
                phaseName: String? = nil, phaseIndex: Int? = nil, phaseCount: Int? = nil, phaseEndsAt: Date? = nil) {
        self.activityName = activityName; self.startedAt = startedAt; self.zoneName = zoneName
        self.zoneIndex = zoneIndex; self.phaseName = phaseName; self.phaseIndex = phaseIndex
        self.phaseCount = phaseCount; self.phaseEndsAt = phaseEndsAt
    }
}

public struct WatchStateSnapshot: Codable, Equatable, Sendable {
    public var revision: Int
    public var mode: WatchWorkoutMode
    public var plan: WatchPlanSnapshot?
    public var exercise: WatchExerciseSnapshot?
    public var rest: WatchRestSnapshot?
    public var cardio: WatchCardioSnapshot?
    public init(revision: Int, mode: WatchWorkoutMode, plan: WatchPlanSnapshot? = nil,
                exercise: WatchExerciseSnapshot? = nil, rest: WatchRestSnapshot? = nil,
                cardio: WatchCardioSnapshot? = nil) {
        self.revision = revision; self.mode = mode; self.plan = plan; self.exercise = exercise
        self.rest = rest; self.cardio = cardio
    }
}

public struct WatchSetDone: Codable, Equatable, Sendable {
    public var commandID: UUID
    public var exerciseID: String
    public var setIndex: Int
    public var actualReps: Double
    public var actualLoad: Double
    public init(commandID: UUID = UUID(), exerciseID: String, setIndex: Int, actualReps: Double, actualLoad: Double) {
        self.commandID = commandID; self.exerciseID = exerciseID; self.setIndex = setIndex
        self.actualReps = actualReps; self.actualLoad = actualLoad
    }
}

/// Messages use one Codable shape over mirrored workout sessions and WatchConnectivity.
public enum WatchMessage: Codable, Equatable, Sendable {
    case hr(Double)
    case cue
    case end
    case ended(saved: Bool)
    case requestState
    case startWorkout(UUID)
    case state(WatchStateSnapshot)
    case setDone(WatchSetDone)
    case skipRest(UUID)
    case navigateExercise(direction: Int, commandID: UUID)
    case acknowledgement(commandID: UUID, accepted: Bool, message: String?)

    public func encoded() -> Data? { try? JSONEncoder().encode(self) }
    public static func decode(_ data: Data) -> WatchMessage? { try? JSONDecoder().decode(WatchMessage.self, from: data) }
}
