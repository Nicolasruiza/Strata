import SwiftUI
import StrataCore

/// What the first-launch screen collects (`onboard`).
struct OnboardState {
    var name = ""
    var gender: String?
    var age = ""
    var off: [Int] = []
    var imported = 0
}

/// Holds the engine (the web's global state) and brings it to SwiftUI.
@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var engine: Engine?
    @Published var onboard: OnboardState?
    @Published var toast: String?
    @Published var selDay: Int?
    @Published var saveFailed = false
    @Published var sheet: Sheet?
    @Published var screen: Screen = .today
    @Published var pending: PendingRoute?
    @Published var pendingEnd: Prompt?
    @Published var celebrationShown = false
    @Published var jumpSets: [String: Int] = [:]
    @Published var swapOpen = false
    @Published var warmOpen = false
    @Published var menuOpen = false
    var restTicker: Task<Void, Never>?
    @Published var countdown: CountdownState?
    @Published var confirmDelete: (date: String, type: String)?

    enum Sheet: Identifiable {
        case cantTrain, walk, editCardio(date: String, type: String)
        var id: String {
            switch self { case .cantTrain: return "cant"; case .walk: return "walk"; case .editCardio(let d, let t): return "edit-\(d)-\(t)" }
        }
    }

    private let store = LocalStore()
    private var toastTask: Task<Void, Never>?

    init() {
        if let p = store.loadProfile() {
            engine = Engine(profile: p, db: store.loadData(), nowMs: Self.nowMs(), tz: .current)
        } else {
            onboard = OnboardState()
        }
    }

    static func nowMs() -> Double { Date().timeIntervalSince1970 * 1000 }

    /// Bring the clock up to date (call when a screen appears or a minute passes).
    func tick() { engine?.nowMs = Self.nowMs(); objectWillChange.send() }

    /// Run a change on the engine, save, and show the toast it returned.
    func mutate(_ change: (inout Engine) -> String?) {
        guard var e = engine else { return }
        e.nowMs = Self.nowMs()
        let t = change(&e)
        engine = e
        persist()
        if e.rest != nil { ensureRestTicker() }
        if let t = t, !t.isEmpty { show(t) }
    }

    func persist() {
        guard let e = engine else { return }
        saveFailed = !store.save(profile: e.profile, data: e.db)
    }

    func show(_ message: String) {
        toast = message
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_800_000_000)
            if !Task.isCancelled { self?.toast = nil }
        }
    }

    // MARK: first launch (app.js onboardView / setGender / obGo)

    func chooseGender(_ g: String) {
        guard onboard != nil else { return }
        onboard!.gender = g
        let keep = engine?.db ?? AppData.fresh()
        var e = Engine(profile: Engine.newProfile(name: onboard!.name, gender: g), db: keep, nowMs: Self.nowMs(), tz: .current)
        if let old = engine { e.db = old.db }
        engine = e
    }

    func importFile(_ url: URL) {
        guard var e = engine, onboard != nil else { return }
        let ok = url.startAccessingSecurityScopedResource()
        defer { if ok { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url), let p = try? AppData.load(from: data),
              (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["history"] is [Any] else {
            show("That file is not a valid export"); return
        }
        e.applyImport(p)
        engine = e
        onboard!.imported = e.db.history.count
        if let a = e.db.age, onboard!.age.isEmpty { onboard!.age = String(Int(a)) }
        if let off = e.db.officeDays { onboard!.off = off } else if e.db.rcOffice == true { onboard!.off = [2, 4] }
        show("Imported \(e.db.history.count) sessions")
    }

    func finishOnboarding() {
        guard var e = engine, let o = onboard, !o.name.trimmingCharacters(in: .whitespaces).isEmpty, o.gender != nil else { return }
        let age = Double(o.age).flatMap { $0 >= 14 && $0 <= 99 ? $0 : nil }
        e.nowMs = Self.nowMs()
        e.completeOnboarding(name: o.name, age: age, officeDays: o.off.sorted())
        engine = e
        onboard = nil
        selDay = nil
        persist()
    }
}

/// Where the user is, outside the locked workout (`scr` in the web).
enum Screen: Equatable {
    case today
    case preview(day: Int)
}

/// Buttons whose destination is built in a later PR record the request here and nothing opens
/// (PARITY.md marks them).
enum PendingRoute: Equatable {
    case detail(historyIndex: Int), pickCardio, howTheFourByFourWorks
}

extension AppModel {
    func navigate(_ r: PendingRoute) { pending = r }
    func go(_ s: Screen) { screen = s }
}

// MARK: workout support: rest timer, haptic cue, 3-2-1 countdown, form videos

struct CountdownState: Equatable { var label: String; var n: Int }

extension AppModel {
    /// `cue()`: haptic (the web also beeps and vibrates). The watch haptic arrives in phase 4.
    func cue() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }

    /// `tickLift`: beep once when rest ends, drop the banner 15 s later.
    func ensureRestTicker() {
        guard restTicker == nil else { return }
        restTicker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard let self = self else { return }
                if self.engine?.rest == nil { self.restTicker = nil; return }
                self.tickRest()
            }
        }
    }

    private func tickRest() {
        guard var e = engine, var r = e.rest else { return }
        e.nowMs = Self.nowMs()
        let rem = (r.endAt - e.nowMs) / 1000
        if rem <= 0 && !r.beeped { r.beeped = true; e.rest = r; engine = e; cue(); return }
        if rem < -15 { e.rest = nil; engine = e; return }
        engine = e
    }

    func extendRest() {
        guard var e = engine, var r = e.rest else { return }
        e.nowMs = Self.nowMs()
        r.endAt = max(r.endAt, e.nowMs) + Config.Rest.extend * 1000
        r.total += Config.Rest.extend
        r.beeped = false
        e.rest = r; engine = e
    }
    func skipRest() { engine?.rest = nil }

    /// The 3-2-1 before a workout (`countdown()`); the watch is started here in phase 4.
    func runCountdown(label: String) {
        countdown = CountdownState(label: label, n: Config.workout.countdownSec)
        Task { [weak self] in
            for n in stride(from: Config.workout.countdownSec, to: 0, by: -1) {
                await MainActor.run { self?.countdown?.n = n }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            await MainActor.run { self?.countdown = nil; self?.cue() }
        }
    }

    func openFormVideo(id: String, name: String) {
        guard let e = engine, let url = URL(string: Fmt.formVideoURL(id: id, name: name, qmapKey: e.ap.qmap)) else { return }
        UIApplication.shared.open(url)
    }
}
