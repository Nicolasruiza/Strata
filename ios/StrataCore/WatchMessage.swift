import Foundation

/// What the phone and the watch send each other over the mirrored workout session
/// (`HKWorkoutSession.sendToRemoteWorkoutSession`). Shared so both ends agree on the shape.
public enum WatchMessage: Codable, Equatable {
    /// watch → phone: a heart-rate reading in bpm
    case hr(Double)
    /// phone → watch: the haptic cue (`cue()` in the web)
    case cue
    /// phone → watch: end the session and save the workout
    case end
    /// watch → phone: what `finishWorkout()` really returned
    case ended(saved: Bool)

    public func encoded() -> Data? { try? JSONEncoder().encode(self) }
    public static func decode(_ data: Data) -> WatchMessage? { try? JSONDecoder().decode(WatchMessage.self, from: data) }
}
