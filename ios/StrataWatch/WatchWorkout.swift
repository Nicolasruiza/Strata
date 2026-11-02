import HealthKit
import StrataCore
import WatchKit

/// The watch's workout: an `HKWorkoutSession` with a live builder, mirrored to the phone.
/// Real sensor data only; when no session is running, the screen says so.
@MainActor
final class WatchWorkout: NSObject, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    static let shared = WatchWorkout()

    @Published private(set) var running = false
    @Published private(set) var hr: Double?
    @Published private(set) var started: Date?

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    func start(_ configuration: HKWorkoutConfiguration) async {
        guard session == nil else { return }
        let hrType = HKQuantityType(.heartRate)
        do {
            try await store.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [hrType])
            let s = try HKWorkoutSession(healthStore: store, configuration: configuration)
            let b = s.associatedWorkoutBuilder()
            b.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: configuration)
            s.delegate = self
            b.delegate = self
            session = s; builder = b
            try await s.startMirroringToCompanionDevice()
            let now = Date()
            s.startActivity(with: now)
            try await b.beginCollection(at: now)
            started = now
            running = true
        } catch {
            session = nil; builder = nil; running = false
        }
    }

    /// Ends the session, saves the workout and tells the phone what `finishWorkout()` returned.
    func end() async {
        guard let s = session, let b = builder else { return }
        s.end()
        var saved = false
        do {
            try await b.endCollection(at: Date())
            saved = try await b.finishWorkout() != nil
        } catch { saved = false }
        send(.ended(saved: saved))
        session = nil; builder = nil
        running = false; hr = nil; started = nil
    }

    private func send(_ m: WatchMessage) {
        guard let s = session, let d = m.encoded() else { return }
        Task { try? await s.sendToRemoteWorkoutSession(data: d) }
    }

    // MARK: HKWorkoutSessionDelegate

    nonisolated func workoutSession(_ s: HKWorkoutSession, didChangeTo to: HKWorkoutSessionState, from: HKWorkoutSessionState, date: Date) {}
    nonisolated func workoutSession(_ s: HKWorkoutSession, didFailWithError error: Error) {}
    nonisolated func workoutSession(_ s: HKWorkoutSession, didReceiveDataFromRemoteWorkoutSession data: [Data]) {
        let messages = data.compactMap(WatchMessage.decode)
        Task { @MainActor in
            for m in messages {
                switch m {
                case .cue: WKInterfaceDevice.current().play(.notification)
                case .end: await self.end()
                case .hr, .ended: break
                }
            }
        }
    }

    // MARK: HKLiveWorkoutBuilderDelegate

    nonisolated func workoutBuilderDidCollectEvent(_ builder: HKLiveWorkoutBuilder) {}
    nonisolated func workoutBuilder(_ builder: HKLiveWorkoutBuilder, didCollectDataOf types: Set<HKSampleType>) {
        let t = HKQuantityType(.heartRate)
        guard types.contains(t), let q = builder.statistics(for: t)?.mostRecentQuantity() else { return }
        let bpm = q.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        Task { @MainActor in
            self.hr = bpm
            self.send(.hr(bpm))
        }
    }
}
