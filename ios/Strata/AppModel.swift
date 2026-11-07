import Combine
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
    @Published var progLift: String?
    @Published var progRange = 8
    @Published var importPrompt: String?
    var importPending: AppData?
    @Published var pickAct: String?
    @Published var vo2N: Int?
    @Published var location: LocationState = .waiting
    @Published var blockSheetOpen = false
    @Published var jumpWeights: [String: Double] = [:]
    @Published var jumpStep = 0
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
    let sensors = AppSensors()
    let health = HealthKitService()
    private var watchSub: AnyCancellable?
    @Published var watchConnected = false
    @Published private(set) var healthAccess = HealthAccessSummary.checking
    @Published private(set) var healthAccessChecking = false
    @Published private(set) var healthSteps: [String: Int] = [:]
    @Published private(set) var stepsLastUpdated: Date?
    @Published private(set) var healthSleep: [String: Double] = [:]
    @Published private(set) var healthWorkoutMinutes: [String: Double] = [:]
    @Published private(set) var todayWorkouts: [HealthWorkoutRow] = []
    @Published private(set) var vo2: [Vo2Reading] = []
    private var watchRevision = 0
    private var handledWatchCommands: Set<UUID> = []
    var liveTicker: Task<Void, Never>?
    private var toastTask: Task<Void, Never>?
    private var lastStepsSync: Date?

    init() {
        sensors.onStateChange = { [weak self] s in Task { @MainActor in self?.location = s } }
        sensors.bridge = health.bridge
        watchSub = health.bridge.$connected.receive(on: DispatchQueue.main).sink { [weak self] c in self?.watchConnected = c }
        health.bridge.onMessage = { [weak self] message in self?.handleWatchMessage(message) }
        if let p = store.loadProfile() {
            engine = Engine(profile: p, db: store.loadData(), nowMs: Self.nowMs(), tz: .current)
            if let L = engine?.db.live { sensors.start(L); ensureLiveTicker() }     // reopened mid-workout
        } else {
            onboard = OnboardState()
        }
        sendWatchState()
        refreshStepsIfNeeded(force: true)
    }

    static func nowMs() -> Double { Date().timeIntervalSince1970 * 1000 }

    func refreshHealthAccess(requestAuthorization: Bool = false) {
        guard !healthAccessChecking else { return }
        healthAccessChecking = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.healthAccess = await self.health.accessSummary(requestAuthorization: requestAuthorization)
            await self.syncSteps()
            self.healthAccessChecking = false
        }
    }

    /// Bring the clock up to date (call when a screen appears or a minute passes).
    func tick() {
        engine?.nowMs = Self.nowMs()
        objectWillChange.send()
        refreshStepsIfNeeded()
    }

    private func refreshStepsIfNeeded(force: Bool = false) {
        if !force, let lastStepsSync, Date().timeIntervalSince(lastStepsSync) < 15 * 60 { return }
        lastStepsSync = Date()
        Task { @MainActor [weak self] in await self?.syncSteps() }
    }

    private func syncSteps() async {
        guard engine != nil else { return }
        let calendar = Calendar.current
        let today = Date()
        guard let start = calendar.date(byAdding: .day, value: -55, to: today) else { return }
        if let readings = await health.vo2Readings(from: calendar.date(byAdding: .day, value: -365, to: today) ?? start, through: today) { vo2 = readings }
        if let rows = await health.workouts(on: today) { todayWorkouts = rows }
        if let workouts = await health.dailyWorkoutMinutes(from: start, through: today) { healthWorkoutMinutes = workouts }
        if let sleep = await health.dailySleep(from: start, through: today), !sleep.isEmpty { healthSleep = sleep }
        guard let totals = await health.dailySteps(from: start, through: today), !totals.isEmpty else { return }
        healthSteps = totals
        stepsLastUpdated = Date()
        if var updated = engine, updated.syncHealthSteps(totals) {
            engine = updated
            persist()
        }
    }

    func syncedSteps(on date: String) -> Int? { healthSteps[date] }
    func syncedSleep(on date: String) -> Double? { healthSleep[date] }
    func healthCardioMinutes(on date: String) -> Double { healthWorkoutMinutes[date] ?? 0 }

    /// Run a change on the engine, save, and show the toast it returned.
    func mutate(_ change: (inout Engine) -> String?) {
        guard var e = engine else { return }
        let wasStrengthRunning = e.db.active != nil
        e.nowMs = Self.nowMs()
        let t = change(&e)
        engine = e
        persist()
        if e.rest != nil { ensureRestTicker() }
        if let t = t, !t.isEmpty { show(t) }
        sendWatchState()
        if !wasStrengthRunning, e.db.active != nil {
            Task { @MainActor [weak self] in
                guard let self else { return }
                if await self.health.startStrengthWatch() { self.show("Apple Watch · Strength started") }
                self.sendWatchState()
            }
        }
    }

    func persist() {
        guard let e = engine else { return }
        saveFailed = !store.save(profile: e.profile, data: e.db)
    }

    private func sendWatchState() {
        guard var e = engine else { return }
        watchRevision += 1
        let snapshot: WatchStateSnapshot
        if let live = e.db.live {
            let name = e.catalog.cardioActs[live.act]?.n ?? live.act
            let cardio = WatchCardioSnapshot(
                activityName: name,
                startedAt: Date(timeIntervalSince1970: live.started / 1000)
            )
            snapshot = WatchStateSnapshot(revision: watchRevision, mode: .cardio, cardio: cardio)
        } else if let active = e.db.active {
            let planName = e.plan[active.day]?.name ?? "Strength"
            let list = e.liftList()
            var exercise: WatchExerciseSnapshot?
            if !list.isEmpty {
                let index = min(max(0, e.curIdx()), list.count - 1)
                let original = list[index]
                let shown = e.shownEx(original)
                let progress = e.progOf(original)
                let setIndex = min((progress?.reps.count ?? 0) + 1, e.setsOf(original))
                let load = progress?.w ?? ((active.lowEnergy ?? false) ? e.loEnergyW(e.wOf(shown)) : e.wOf(shown))
                let previous = e.db.history.reversed().compactMap { $0.entries[shown.id] }.first
                let last = previous.map { entry in
                    let reps = entry.reps.map { value in value.map(watchNumber) ?? "—" }.joined(separator: " · ")
                    return "Last: \(reps) at \(watchNumber(entry.w))"
                }
                let timed = Fmt.isSec(shown)
                exercise = WatchExerciseSnapshot(
                    id: shown.id,
                    name: Fmt.cleanN(shown.n),
                    imageName: e.catalog.imageName(of: shown.id).map { ($0 as NSString).deletingPathExtension },
                    setIndex: setIndex,
                    setCount: e.setsOf(original),
                    targetReps: e.woReps ?? Double(shown.r ?? 0),
                    load: load,
                    loadUnit: "lb",
                    loadIncrement: (shown.inc ?? 0) == 0 ? 5 : shown.inc!,
                    lastSummary: last,
                    durationSeconds: timed ? shown.r : nil,
                    restSeconds: Int(e.restFor(original))
                )
            }
            let rest = e.rest.map { value -> WatchRestSnapshot in
                let next = e.nextUp().map { e.shownEx($0) }
                let nextTarget = next.map { "\($0.r ?? 0) \(Fmt.isSec($0) ? "sec" : "reps") · \(watchNumber(e.wOf($0))) lb" }
                return WatchRestSnapshot(endsAt: Date(timeIntervalSince1970: value.endAt / 1000),
                                         nextName: next.map { Fmt.cleanN($0.n) }, nextTarget: nextTarget)
            }
            snapshot = WatchStateSnapshot(revision: watchRevision, mode: .strength,
                                           plan: WatchPlanSnapshot(name: "Strength · \(planName)", detail: "\(list.count) exercises"),
                                           exercise: exercise, rest: rest)
        } else {
            let weekday = Dates.weekday(e.today)
            let monday = Dates.mondayOf(e.today)
            let lift = e.liftSlots(monday)[weekday]
            let plan = lift?.day.flatMap { day -> WatchPlanSnapshot? in
                guard let name = e.plan[day]?.name else { return nil }
                return WatchPlanSnapshot(name: "Strength · \(name)", detail: "\(e.requiredItems(day).count) exercises")
            }
            snapshot = WatchStateSnapshot(revision: watchRevision, mode: .idle, plan: plan)
        }
        health.bridge.send(.state(snapshot))
    }

    private func handleWatchMessage(_ message: WatchMessage) {
        switch message {
        case .requestState:
            sendWatchState()
        case .startWorkout(let commandID):
            guard handledWatchCommands.insert(commandID).inserted else {
                health.bridge.send(.acknowledgement(commandID: commandID, accepted: true, message: nil)); return
            }
            guard var e = engine else { return }
            let weekday = Dates.weekday(e.today)
            let monday = Dates.mondayOf(e.today)
            guard let day = e.liftSlots(monday)[weekday]?.day else {
                health.bridge.send(.acknowledgement(commandID: commandID, accepted: false, message: "No strength plan today")); return
            }
            e.begin(day: day)
            engine = e; persist(); sendWatchState()
            health.bridge.send(.acknowledgement(commandID: commandID, accepted: true, message: nil))
            Task { @MainActor [weak self] in
                guard let self else { return }
                _ = await self.health.startStrengthWatch()
                self.sendWatchState()
            }
        case .setDone(let command):
            completeSetFromWatch(command)
        case .skipRest(let commandID):
            guard handledWatchCommands.insert(commandID).inserted else {
                health.bridge.send(.acknowledgement(commandID: commandID, accepted: true, message: nil)); return
            }
            skipRest()
            health.bridge.send(.acknowledgement(commandID: commandID, accepted: true, message: nil))
        case .navigateExercise(let direction, let commandID):
            guard handledWatchCommands.insert(commandID).inserted else {
                health.bridge.send(.acknowledgement(commandID: commandID, accepted: true, message: nil)); return
            }
            guard var e = engine, e.db.active != nil, !e.liftList().isEmpty else {
                health.bridge.send(.acknowledgement(commandID: commandID, accepted: false, message: "Workout unavailable")); return
            }
            let next = min(max(0, e.curIdx() + direction), e.liftList().count - 1)
            _ = e.openEx(next)
            engine = e; persist(); sendWatchState()
            health.bridge.send(.acknowledgement(commandID: commandID, accepted: true, message: nil))
        default:
            break
        }
    }

    private func completeSetFromWatch(_ command: WatchSetDone) {
        if handledWatchCommands.contains(command.commandID) {
            health.bridge.send(.acknowledgement(commandID: command.commandID, accepted: true, message: nil)); return
        }
        guard var e = engine, e.db.active != nil, !e.liftList().isEmpty else {
            health.bridge.send(.acknowledgement(commandID: command.commandID, accepted: false, message: "Workout unavailable")); return
        }
        let original = e.liftList()[e.curIdx()]
        let shown = e.shownEx(original)
        let expectedSet = (e.progOf(original)?.reps.count ?? 0) + 1
        guard shown.id == command.exerciseID, expectedSet == command.setIndex else {
            health.bridge.send(.acknowledgement(commandID: command.commandID, accepted: false, message: "Set changed on iPhone"))
            sendWatchState()
            return
        }
        var progress = e.progOf(original) ?? Prog(w: command.actualLoad, reps: [])
        progress.w = max(0, command.actualLoad)
        e.db.active!.prog[shown.id] = progress
        e.woReps = max(0, command.actualReps)
        _ = e.logWoSet()
        handledWatchCommands.insert(command.commandID)
        engine = e; persist()
        if e.rest != nil { ensureRestTicker() }
        health.bridge.send(.acknowledgement(commandID: command.commandID, accepted: true, message: nil))
        sendWatchState()
    }

    private func watchNumber(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
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
    case progress
    case history
    case detail(index: Int)
    case activity(date: String, type: String)
    case mobility(session: String)
    case settings
    case preview(day: Int)
    case pick
    case cdone
    case vo2
    case vo2done
}

/// Buttons whose destination is built in a later PR record the request here and nothing opens
/// (PARITY.md marks them).
enum PendingRoute: Equatable {
    case detail(historyIndex: Int)              // handled: opens the session detail
    case pickCardio, howTheFourByFourWorks      // handled: they open the picker / the 4×4 screen
}

extension AppModel {
    func navigate(_ r: PendingRoute) {
        switch r {
        case .pickCardio: pickAct = nil; go(.pick)
        case .howTheFourByFourWorks: vo2N = nil; go(.vo2)
        case .detail(let i): go(.detail(index: i))
        }
    }
    func go(_ s: Screen) { screen = s }
}

// MARK: workout support: rest timer, haptic cue, 3-2-1 countdown, form videos

struct CountdownState: Equatable { var label: String; var n: Int }

extension AppModel {
    /// `cue()`: haptic (the web also beeps and vibrates). The watch gets the same cue.
    func cue() { UINotificationFeedbackGenerator().notificationOccurred(.warning); health.bridge.sendCue() }

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
    func skipRest() { engine?.rest = nil; persist(); sendWatchState() }

    /// The 3-2-1 before a workout (`countdown()`); the watch is started here in phase 4.
    func runCountdown(label: String, then: (@MainActor () -> Void)? = nil) {
        countdown = CountdownState(label: label, n: Config.workout.countdownSec)
        Task { [weak self] in
            for n in stride(from: Config.workout.countdownSec, to: 0, by: -1) {
                await MainActor.run { self?.countdown?.n = n }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            await MainActor.run { self?.countdown = nil; self?.cue(); then?() }
        }
    }

    func openFormVideo(id: String, name: String) {
        guard let e = engine, let url = URL(string: Fmt.formVideoURL(id: id, name: name, qmapKey: e.ap.qmap)) else { return }
        UIApplication.shared.open(url)
    }
}


// MARK: cardio (workout.js startCardio / takeSample / completeCardio)

extension AppModel {
    /// "Start · <activity>": the 3-2-1, then the live session.
    func startCardio() {
        guard let e = engine else { return }
        let P = e.cardioPlan(), act = pickAct ?? P.act
        let name = e.catalog.cardioActs[act]?.n ?? act
        runCountdown(label: name + (P.mode != "free" ? " · " + Engine.modeLbl(P.mode) : "")) { [weak self] in
            guard let self = self else { return }
            let reading = SensorReading(hr: nil, alt: nil)
            self.mutate { $0.startCardio(act: act, reading: reading); return nil }
            self.pickAct = nil
            if let L = self.engine?.db.live { self.sensors.start(L) }
            self.ensureLiveTicker()
            self.screen = .today
            // The web starts the watch right after the countdown and says so when it did.
            Task { @MainActor in
                if await self.health.startWatch(WatchStartConfig(activity: act)) { self.show("Apple Watch · \(name) started") }
            }
        }
    }

    /// One reading every `sampleEverySec`, stored on the live session.
    func ensureLiveTicker() {
        guard liveTicker == nil else { return }
        UIApplication.shared.isIdleTimerDisabled = true
        liveTicker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self = self else { return }
                guard let e = self.engine, let L = e.db.live else { self.liveTicker = nil; UIApplication.shared.isIdleTimerDisabled = false; return }
                let r = self.sensors.read(e.liveElapsed(L))
                self.mutate { $0.takeSample(reading: r); return nil }
            }
        }
    }

    func completeCardio() {
        guard var e = engine, let L = e.db.live else { return }
        e.nowMs = Self.nowMs()
        let payload = e.endCardio(reading: sensors.read(e.liveElapsed(L)))
        e.recordHealthResult(saved: false)      // closes the session; the real result lands below
        engine = e
        persist()
        sensors.stop()
        liveTicker?.cancel(); liveTicker = nil
        UIApplication.shared.isIdleTimerDisabled = false
        screen = .cdone
        blockSheetOpen = true
        // The footer shows what saveWorkout() really returned.
        Task { @MainActor in
            let saved = payload == nil ? false : await health.saveWorkout(payload!)
            mutate { $0.wLast?.health = saved; return nil }
        }
    }

    func discardCardio() {
        mutate { $0.discardCardio(); return nil }
        sensors.stop()
        liveTicker?.cancel(); liveTicker = nil
        UIApplication.shared.isIdleTimerDisabled = false
        screen = .today
    }

    func logVo2Block() {
        mutate { $0.logVo2(n: self.vo2N); return nil }
        screen = .vo2done
    }
}
