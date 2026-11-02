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
    @Published var route: Route?
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

/// Where a button on Today leads. The destinations are built in the next PRs; until then
/// `navigate` records the request and nothing is shown (PARITY.md marks these buttons).
enum Route: Equatable {
    case preview(day: Int), detail(historyIndex: Int), pickCardio, resume, howTheFourByFourWorks
}

extension AppModel {
    func navigate(_ r: Route) { route = r }
}
