import HealthKit
import StrataCore
import WatchConnectivity

/// The phone's end of the Strata watch app's workout: the watch runs the `HKWorkoutSession`
/// (heart rate, saving to Health) and mirrors it here. Nothing is simulated: with no watch
/// session, `connected` is false and heart rate stays "—".
final class WatchBridge: NSObject, ObservableObject, HKWorkoutSessionDelegate, WCSessionDelegate {
    /// For the UI (set on the main queue).
    @Published private(set) var connected = false
    // Everything below is read from the sensor ticker and written by HealthKit callbacks.
    private let lock = NSLock()
    private var liveConnected = false
    private var hr: Double?
    private var hrAt: Date?
    private var session: HKWorkoutSession?
    private var endWaiter: CheckedContinuation<Bool?, Never>?
    var isConnected: Bool { lock.lock(); defer { lock.unlock() }; return liveConnected }
    private func setConnected(_ c: Bool) {
        lock.lock(); liveConnected = c; lock.unlock()
        DispatchQueue.main.async { self.connected = c }
    }
    private let store: HKHealthStore
    @MainActor var onMessage: ((WatchMessage) -> Void)?
    private var connectivity: WCSession? { WCSession.isSupported() ? .default : nil }

    init(store: HKHealthStore) {
        self.store = store
        super.init()
        store.workoutSessionMirroringStartHandler = { [weak self] session in self?.attach(session) }
        connectivity?.delegate = self
        connectivity?.activate()
    }

    private func attach(_ s: HKWorkoutSession) {
        lock.lock(); session = s; hr = nil; hrAt = nil; lock.unlock()
        s.delegate = self
        setConnected(true)
    }

    /// The latest reading, or nil when it is older than `maxSampleGapSec`.
    func reading(now: Date = Date()) -> Double? {
        lock.lock(); defer { lock.unlock() }
        guard let hr = hr, let at = hrAt, now.timeIntervalSince(at) <= Config.workout.maxSampleGapSec else { return nil }
        return hr
    }

    func sendCue() { send(.cue) }

    func send(_ m: WatchMessage) {
        lock.lock(); let s = session; lock.unlock()
        guard let d = m.encoded() else { return }
        if let s {
            Task { try? await s.sendToRemoteWorkoutSession(data: d) }
        }
        if m.isStateSnapshot {
            try? connectivity?.updateApplicationContext(["message": d])
        } else if connectivity?.isReachable == true {
            connectivity?.sendMessageData(d, replyHandler: nil)
        }
    }

    /// Ends the watch session and returns what the watch's save really returned
    /// (nil when there was no session or no answer in time, so the caller can say "not saved").
    func endAndWaitForSave(timeout: TimeInterval = 15) async -> Bool? {
        lock.lock(); let live = session != nil && liveConnected; lock.unlock()
        guard live else { return nil }
        send(.end)
        return await withCheckedContinuation { cont in
            lock.lock(); endWaiter = cont; lock.unlock()
            Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                self.finish(nil)
            }
        }
    }

    private func finish(_ saved: Bool?) {
        lock.lock()
        let w = endWaiter; endWaiter = nil
        session = nil; hr = nil; hrAt = nil
        lock.unlock()
        setConnected(false)
        w?.resume(returning: saved)
    }

    // MARK: HKWorkoutSessionDelegate

    nonisolated func workoutSession(_ s: HKWorkoutSession, didChangeTo to: HKWorkoutSessionState, from: HKWorkoutSessionState, date: Date) {}
    nonisolated func workoutSession(_ s: HKWorkoutSession, didFailWithError error: Error) {
        setConnected(false)
    }
    nonisolated func workoutSession(_ s: HKWorkoutSession, didDisconnectFromRemoteDeviceWithError error: Error?) {
        lock.lock(); let ending = endWaiter != nil; lock.unlock()
        if !ending { setConnected(false) }
    }
    nonisolated func workoutSession(_ s: HKWorkoutSession, didReceiveDataFromRemoteWorkoutSession data: [Data]) {
        let messages = data.compactMap(WatchMessage.decode)
        for m in messages {
            switch m {
            case .hr(let v): lock.lock(); hr = v; hrAt = Date(); lock.unlock()
            case .ended(let saved): finish(saved)
            default: deliver(m)
            }
        }
    }

    private nonisolated func deliver(_ message: WatchMessage) {
        Task { @MainActor [weak self] in self?.onMessage?(message) }
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {}
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        guard let message = WatchMessage.decode(messageData) else { return }
        deliver(message)
    }
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext["message"] as? Data, let message = WatchMessage.decode(data) else { return }
        deliver(message)
    }
}

private extension WatchMessage {
    var isStateSnapshot: Bool {
        if case .state = self { return true }
        return false
    }
}
