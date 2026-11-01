import Foundation

/// What the Watch start call is asked to run (`HKWorkoutConfiguration` on iOS).
public struct WatchStartConfig: Equatable {
    public var activity: String
    public init(activity: String) { self.activity = activity }
}

/// workout.js `Sensors`: real sources only. On iOS, heart rate comes from the Strata watch
/// app and altitude from the workout route / altimeter. There is no demo source, anywhere.
public protocol Sensors {
    func start(_ live: LiveCardio)
    func stop()
    /// A reading at elapsed second `t`; nil values mean "no data" and are shown as "—".
    func read(_ t: Double) -> SensorReading
    /// Where heart rate is coming from ("watch"), or nil when there is no source.
    func hrSource() -> String?
}

/// workout.js `Health`: its results are shown to the user as they are.
public protocol HealthService {
    var available: Bool { get }
    /// `startWatch(cfg)` → `{started}`
    func startWatch(_ cfg: WatchStartConfig) async -> Bool
    /// `saveWorkout(entry)` → `{saved}`
    func saveWorkout(_ entry: HealthPayload) async -> Bool
}
