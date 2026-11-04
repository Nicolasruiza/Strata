import HealthKit
import StrataCore
import WatchConnectivity
import WatchKit

/// Owns the real HealthKit workout and the versioned companion state received from iPhone.
@MainActor
final class WatchWorkout: NSObject, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate, WCSessionDelegate {
    static let shared = WatchWorkout()

    @Published private(set) var running = false
    @Published private(set) var hr: Double?
    @Published private(set) var started: Date?
    @Published private(set) var state = WatchStateSnapshot(revision: 0, mode: .idle)
    @Published private(set) var pendingCommandID: UUID?
    @Published private(set) var commandError: String?

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var restTask: Task<Void, Never>?
    private var connectivity: WCSession? { WCSession.isSupported() ? .default : nil }

    override init() {
        super.init()
        connectivity?.delegate = self
        connectivity?.activate()
    }

    func start(_ configuration: HKWorkoutConfiguration) async {
        guard session == nil else { requestState(); return }
        let hrType = HKQuantityType(.heartRate)
        do {
            try await store.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [hrType])
            let workoutSession = try HKWorkoutSession(healthStore: store, configuration: configuration)
            let workoutBuilder = workoutSession.associatedWorkoutBuilder()
            workoutBuilder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: configuration)
            workoutSession.delegate = self
            workoutBuilder.delegate = self
            session = workoutSession
            builder = workoutBuilder
            try await workoutSession.startMirroringToCompanionDevice()
            let now = Date()
            workoutSession.startActivity(with: now)
            try await workoutBuilder.beginCollection(at: now)
            started = now
            running = true
            requestState()
        } catch {
            session = nil
            builder = nil
            running = false
            commandError = "Couldn’t start workout"
        }
    }

    func end() async {
        guard let session, let builder else { return }
        session.end()
        var saved = false
        do {
            try await builder.endCollection(at: Date())
            saved = try await builder.finishWorkout() != nil
        } catch {
            saved = false
        }
        send(.ended(saved: saved))
        self.session = nil
        self.builder = nil
        running = false
        hr = nil
        started = nil
    }

    func completeSet(reps: Double, load: Double) {
        guard pendingCommandID == nil, let exercise = state.exercise else { return }
        let command = WatchSetDone(exerciseID: exercise.id, setIndex: exercise.setIndex,
                                   actualReps: reps, actualLoad: load)
        pendingCommandID = command.commandID
        commandError = nil
        send(.setDone(command))
    }

    func skipRest() {
        guard pendingCommandID == nil else { return }
        let id = UUID()
        pendingCommandID = id
        send(.skipRest(id))
    }

    func startPlan() {
        guard pendingCommandID == nil else { return }
        let id = UUID()
        pendingCommandID = id
        send(.startWorkout(id))
    }

    func navigateExercise(_ direction: Int) {
        guard pendingCommandID == nil else { return }
        let id = UUID()
        pendingCommandID = id
        send(.navigateExercise(direction: direction, commandID: id))
    }

    func requestState() { send(.requestState) }

    private func send(_ message: WatchMessage) {
        guard let data = message.encoded() else { return }
        if let session {
            Task { try? await session.sendToRemoteWorkoutSession(data: data) }
        }
        if connectivity?.isReachable == true {
            connectivity?.sendMessageData(data, replyHandler: nil)
        }
    }

    private func receive(_ message: WatchMessage) {
        switch message {
        case .state(let snapshot):
            guard snapshot.revision >= state.revision else { return }
            state = snapshot
            scheduleRestHaptic(snapshot.rest)
        case .acknowledgement(let id, let accepted, let message):
            guard pendingCommandID == id else { return }
            pendingCommandID = nil
            commandError = accepted ? nil : (message ?? "Try again")
            if accepted { WKInterfaceDevice.current().play(.success) }
        case .cue:
            WKInterfaceDevice.current().play(.start)
        case .end:
            Task { await end() }
        default:
            break
        }
    }

    private func scheduleRestHaptic(_ rest: WatchRestSnapshot?) {
        restTask?.cancel()
        guard let rest else { return }
        let delay = max(0, rest.endsAt.timeIntervalSinceNow)
        restTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled, self?.state.rest?.endsAt == rest.endsAt else { return }
            WKInterfaceDevice.current().play(.start)
        }
    }

    nonisolated func workoutSession(_ session: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                                    from fromState: HKWorkoutSessionState, date: Date) {}

    nonisolated func workoutSession(_ session: HKWorkoutSession, didFailWithError error: Error) {
        Task { @MainActor [weak self] in self?.commandError = "Workout connection lost" }
    }

    nonisolated func workoutSession(_ session: HKWorkoutSession, didReceiveDataFromRemoteWorkoutSession data: [Data]) {
        let messages = data.compactMap(WatchMessage.decode)
        Task { @MainActor [weak self] in messages.forEach { self?.receive($0) } }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf types: Set<HKSampleType>) {
        let heartRate = HKQuantityType(.heartRate)
        guard types.contains(heartRate), let quantity = workoutBuilder.statistics(for: heartRate)?.mostRecentQuantity() else { return }
        let bpm = quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        Task { @MainActor [weak self] in
            self?.hr = bpm
            self?.send(.hr(bpm))
        }
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        guard activationState == .activated else { return }
        Task { @MainActor [weak self] in self?.requestState() }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable else { return }
        Task { @MainActor [weak self] in self?.requestState() }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        guard let message = WatchMessage.decode(messageData) else { return }
        Task { @MainActor [weak self] in self?.receive(message) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext["message"] as? Data,
              let message = WatchMessage.decode(data) else { return }
        Task { @MainActor [weak self] in self?.receive(message) }
    }
}
