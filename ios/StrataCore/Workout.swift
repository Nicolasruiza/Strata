import Foundation

public struct WoBlock: Codable, Equatable {
    public var t: String
    public var kind: String
    public var opt: Bool
    public var items: [String]
}

public struct Trend: Codable, Equatable {
    public var t: String          // First time · Progressing · On track · Behind · Stalled · On hold
    public var c: String          // chip colour class: n · up · hold · bad
}

public struct WarmOption: Codable, Equatable {
    public var w: Double
    public var r: Double
    public var label: String
}

public struct BusyResult: Codable, Equatable {
    public var toasts: [String]
    public var offerSwap: Bool
    public var openedIndex: Int?
}

public struct Prompt: Codable, Equatable {
    public enum Kind: String, Codable { case discard, finish }
    public var kind: Kind
    public var message: String
}

public struct SummaryRow: Codable, Equatable {
    public var id: String
    public var up: Bool
    public var next: Double?
    public var need: Double
    public var unlocks: Double?
}

public struct SummaryCompare: Codable, Equatable {
    public struct Item: Codable, Equatable { public var id: String; public var a: Double; public var b: Double; public var p: Double }
    public var prevDate: String
    public var pct: Double
    public var items: [Item]
}

public struct SessionSummary: Codable, Equatable {
    public var mainN: Int
    public var bonusN: Int
    public var reqCount: Int
    public var rows: [SummaryRow]
    public var compare: SummaryCompare?
}

public struct EndResult: Codable, Equatable {
    public var discarded: Bool
}

extension Engine {
    /// Upper bound mirrored from the `#wIn` change listener in workout.js.
    private static let maximumTypedWeight = 2_000.0

    // MARK: the lift list (app.js liftList … progOf, workout.js exState, nextUp)

    public func liftList() -> [Ex] {
        guard let A = db.active else { return [] }
        let warm = Set((plan[A.day]?.blocks ?? []).filter { Engine.isWarmUp($0.t) }.flatMap { $0.items.map(\.id) })
        return sessionItems(A.day, lowEnergy: A.lowEnergy ?? false).filter { !warm.contains($0.id) }
    }

    public func shownEx(_ ex: Ex) -> Ex {
        if let to = db.active?.swaps[ex.id] { return ap.all.first { $0.id == to } ?? ex }
        return ex
    }

    public func isLogged(_ ex: Ex) -> Bool {
        guard let A = db.active else { return false }
        return A.entries[A.swaps[ex.id] ?? ex.id] != nil
    }

    public func curIdx() -> Int {
        let A = db.active!, L = liftList()
        if let i = A.idx, i >= 0, i < L.count { return i }
        let req = Set(requiredItems(A.day).map(\.id))
        var i = L.firstIndex { req.contains($0.id) && !isLogged($0) }
        if i == nil { i = L.firstIndex { !isLogged($0) } }
        return i ?? 0
    }

    public func setsOf(_ ex: Ex) -> Int {
        let A = db.active!
        return ((A.lowEnergy ?? false) ? Config.lighterDaySets : ex.setCount) + (A.extra?[shownEx(ex).id] ?? 0)
    }

    public func progOf(_ ex: Ex) -> Prog? {
        let A = db.active!, s = shownEx(ex)
        if let p = A.prog[s.id] { return p }
        if let e = A.entries[s.id] { return Prog(w: e.w, reps: e.reps) }
        return nil
    }

    public func exState(_ ex: Ex) -> String {
        let p = progOf(ex), n = p?.reps.count ?? 0, need = setsOf(ex)
        return isLogged(ex) && n >= need ? "done" : n > 0 ? "live" : "todo"
    }

    /// `nextUp()`: the first unfinished lift, skipping ones marked busy for `busyMin` minutes.
    public func nextUp() -> Ex? {
        let A = db.active!, L = liftList(), busy = A.busy ?? [:]
        return L.first { x in
            exState(x) != "done" && !((busy[x.id] ?? 0) != 0 && nowMs - busy[x.id]! < Config.workout.busyMin * 60_000)
        } ?? L.first { exState($0) != "done" }
    }

    public static func blockKind(_ t: String) -> String {
        func m(_ p: String) -> Bool { t.range(of: p, options: [.regularExpression, .caseInsensitive]) != nil }
        return m("^warm") ? "Warm-up" : m("^basics") ? "Basics" : m("^compound") ? "Compound" : "Isolation"
    }

    /// `woBlocks()`: the overview's groups (the jumps warm-up has its own row).
    public func woBlocks() -> [WoBlock] {
        guard let A = db.active else { return [] }
        let L = Set(liftList().map(\.id))
        return (plan[A.day]?.blocks ?? []).filter { !Engine.isWarm($0.t) }.map { b in
            WoBlock(t: b.t, kind: Engine.blockKind(b.t), opt: Engine.isOptionalBlock(b.t), items: b.items.filter { L.contains($0.id) }.map(\.id))
        }.filter { !$0.items.isEmpty }
    }

    /// `trendOf(id)`
    public func trendOf(_ id: String) -> Trend {
        let ex = exById(id)
        let hs = Array(db.history.filter { $0.entries[id] != nil }.suffix(4).map { $0.entries[id]! })
        guard let last = hs.last else { return Trend(t: "First time", c: "n") }
        if (db.holds[id] ?? 0) != 0 { return Trend(t: "On hold", c: "hold") }
        let hit = last.reps.allSatisfy { r in
            guard let r = r else { return false }
            guard let need = ex?.r else { return ex == nil }
            return r >= Double(need)
        }
        if hs.count >= 3, hs.suffix(3).allSatisfy({ $0.w == last.w }), !hit { return Trend(t: "Stalled", c: "bad") }
        if hs.count >= 2, last.w > hs[hs.count - 2].w { return Trend(t: "Progressing", c: "up") }
        if hit { return Trend(t: "On track", c: "up") }
        return Trend(t: "Behind", c: "hold")
    }

    /// `restFor(ex)`: key lifts rest longest, optional blocks shortest.
    public func restFor(_ ex: Ex) -> Double {
        if ex.isKey { return Config.Rest.keyLift }
        let t = (plan[db.active!.day]?.blocks.first { $0.items.contains { $0.id == ex.id } })?.t
        return Engine.isOptionalBlock(t ?? "") ? Config.Rest.optionalBlock : Config.Rest.standard
    }

    public mutating func startRest(_ sec: Double, next: String?, lbl: String? = nil) {
        rest = RestState(endAt: nowMs + sec * 1000, total: sec, next: next, lbl: (lbl?.isEmpty ?? true) ? "Up next" : lbl!, beeped: false)
    }

    /// Base weight for an exercise today: lighter-day weight when that is on.
    mutating func baseWeight(_ ex: Ex) -> Double {
        let w = wOf(ex)
        return (db.active?.lowEnergy ?? false) ? loEnergyW(w) : w
    }

    // MARK: starting, opening, logging (workout.js)

    /// `beginBtn` pre-check: a message to confirm, or a toast when a workout is already open.
    public enum BeginCheck: Equatable { case alreadyOpen(toast: String), confirm(String), ok }
    public func beginCheck(day: Int) -> BeginCheck {
        if db.active != nil { return .alreadyOpen(toast: "Finish the open workout first") }
        let g = gate(view: day)
        if !g.ok { return .confirm(g.msg.replacingOccurrences(of: "**", with: "") + "\n\nStart anyway?") }
        return .ok
    }

    /// `begin(day)`
    public mutating func begin(day: Int) {
        celebration = nil
        db.active = ActiveWorkout(day: day, date: today, started: nowMs, lowEnergy: preLow)
        preLow = false
    }
    public mutating func togglePreviewLighter() { preLow.toggle() }

    /// The exercise screen's first-open timer plus the order tip. Returns the tip toast.
    @discardableResult
    public mutating func openEx(_ i: Int) -> String? {
        let L = liftList()
        guard i >= 0, i < L.count, db.active != nil else { return nil }
        let ex = L[i]
        let bl = woBlocks()
        var tip: String?
        if let bi = bl.firstIndex(where: { $0.items.contains(ex.id) }) {
            let busy = db.active!.busy ?? [:]
            let earlier = bl[0..<bi].first { b in
                !b.opt && b.items.contains { id in
                    guard let x = L.first(where: { $0.id == id }) else { return false }
                    return exState(x) != "done" && (busy[x.id] ?? 0) == 0
                }
            }
            if let e = earlier, exState(ex) == "todo" { tip = "Tip: finish \(e.kind) before \(bl[bi].kind)" }
        }
        db.active!.idx = i
        db.active!.view = "focus"
        var exT = db.active!.exT ?? [:]
        let id = shownEx(ex).id
        if (exT[id] ?? 0) == 0 { exT[id] = nowMs }
        db.active!.exT = exT
        woReps = nil
        return tip
    }

    /// `woList` back button.
    public mutating func backToList() { db.active?.view = "list"; woReps = nil }

    /// The first screen of a resumed or fresh strength workout (`resume`, `render` wrapper).
    public var needsJumps: Bool {
        guard let A = db.active else { return false }
        return (A.jumpsSeen ?? 0) == 0 && isLegs(A.day)
    }
    public mutating func markCountdownShown() { db.active?.cd = 1 }

    /// `logWoSet()`: log the current set; start the rest timer. Returns the toast when an exercise completes.
    @discardableResult
    public mutating func logWoSet() -> String? {
        let L = liftList(), idx = curIdx(), orig = L[idx], ex = shownEx(orig), n = setsOf(orig)
        var p = progOf(orig) ?? Prog(w: baseWeight(ex), reps: [])
        let r: Double? = woReps ?? ((p.reps.last ?? nil) ?? orig.r.map(Double.init))
        p.reps.append(r)
        db.active!.prog[ex.id] = p
        woReps = nil
        if p.reps.count >= n {
            db.active!.entries[ex.id] = Entry(w: p.w, reps: Array(p.reps.prefix(n)))
            let nx = nextUp()
            if let nx = nx { startRest(restFor(orig), next: "Next: \(Fmt.cleanN(shownEx(nx).n))", lbl: "Logged") }
            db.active!.view = "list"
            return "\(Fmt.cleanN(ex.n)) done" + (nx != nil ? " · next: \(Fmt.cleanN(shownEx(nx!).n))" : " · all lifts done")
        }
        startRest(restFor(orig), next: "Set \(p.reps.count + 1) of \(n)")
        return nil
    }

    /// The reps stepper: `±1`, or `±5` on timed lifts.
    public mutating func adjustReps(_ dir: Int) {
        let orig = liftList()[curIdx()], ex = shownEx(orig), p = progOf(orig)
        let base: Double = woReps ?? ((p != nil && !p!.reps.isEmpty) ? ((p!.reps.last ?? nil) ?? 0) : Double(orig.r ?? 0))
        woReps = max(0, base + Double(dir) * (Fmt.isSec(ex) ? 5 : 1))
    }

    public mutating func undoSet() {
        let orig = liftList()[curIdx()], ex = shownEx(orig)
        guard var p = progOf(orig) else { return }
        _ = p.reps.popLast()
        db.active!.prog[ex.id] = p
        db.active!.entries[ex.id] = nil
    }

    /// Weight − / +: one `inc` (5 lb when the lift has none).
    public mutating func adjustWeight(_ dir: Int) {
        let orig = liftList()[curIdx()], ex = shownEx(orig)
        var p = progOf(orig) ?? Prog(w: baseWeight(ex), reps: [])
        p.w = max(0, p.w + Double(dir) * ((ex.inc ?? 0) != 0 ? ex.inc! : 5))
        db.active!.prog[ex.id] = p
        if db.active!.entries[ex.id] != nil { db.active!.entries[ex.id]!.w = p.w }
    }

    public mutating func setWeight(_ input: String) -> String? {
        let normalized = input.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value >= 0, value <= Self.maximumTypedWeight else {
            return "Type a weight in lb"
        }

        let orig = liftList()[curIdx()], ex = shownEx(orig)
        var p = progOf(orig) ?? Prog(w: baseWeight(ex), reps: [])
        p.w = (value * 100).rounded() / 100
        db.active!.prog[ex.id] = p
        if db.active!.entries[ex.id] != nil { db.active!.entries[ex.id]!.w = p.w }
        return nil
    }

    /// "+ Set". Returns the toast.
    public mutating func addExtraSet() -> String {
        let ex = shownEx(liftList()[curIdx()])
        var e = db.active!.extra ?? [:]
        e[ex.id] = (e[ex.id] ?? 0) + 1
        db.active!.extra = e
        return "Extra set added"
    }

    /// `warmSheet()` options: empty bar, then 50% and 70% of today's weight.
    public mutating func warmupOptions() -> [WarmOption] {
        let orig = liftList()[curIdx()], ex = shownEx(orig)
        let w = progOf(orig)?.w ?? baseWeight(ex)
        var opts: [WarmOption] = []
        if let bar = ex.bar { opts.append(WarmOption(w: bar, r: Double(Config.workout.emptyBarReps), label: "Empty bar")) }
        for s in Config.workout.warmupSteps {
            let f = s[0], r = s[1], v = PlanBuilder.round5(w * f)
            if v > 0 && v < w && !opts.contains(where: { $0.w == v }) {
                opts.append(WarmOption(w: v, r: r, label: "\(jsNum(jsRound(f * 100)))% of today"))
            }
        }
        return opts
    }
    public mutating func addWarmup(w: Double, r: Double) {
        let ex = shownEx(liftList()[curIdx()])
        var warm = db.active!.warm ?? [:]
        warm[ex.id, default: []].append(WarmSet(w: w, r: r, done: false))
        db.active!.warm = warm
    }
    public mutating func toggleWarmup(_ i: Int) {
        let ex = shownEx(liftList()[curIdx()])
        db.active!.warm?[ex.id]?[i].done.toggle()
    }
    public mutating func removeWarmup(_ i: Int) {
        let ex = shownEx(liftList()[curIdx()])
        db.active!.warm?[ex.id]?.remove(at: i)
    }

    /// "Machine busy": skip to the next unfinished lift in the block, or offer a swap.
    public mutating func markBusy() -> BusyResult {
        let L = liftList(), orig = L[curIdx()], blk = woBlocks().first { $0.items.contains(orig.id) }
        var busy = db.active!.busy ?? [:]
        busy[orig.id] = nowMs
        db.active!.busy = busy
        let alt = blk.flatMap { b in b.items.compactMap { id in L.first { $0.id == id } }.first { $0.id != orig.id && exState($0) != "done" } }
        if let alt = alt {
            var toasts = ["Switched to \(Fmt.cleanN(shownEx(alt).n)). \(Fmt.cleanN(shownEx(orig).n)) comes back up in \(jsNum(Config.workout.busyMin)) min."]
            let i = L.firstIndex { $0.id == alt.id }!
            if let tip = openEx(i) { toasts.append(tip) }
            return BusyResult(toasts: toasts, offerSwap: false, openedIndex: i)
        }
        if !(ap.altOf[orig.id] ?? []).isEmpty {
            return BusyResult(toasts: ["Nothing else left in this block. Swap to free equipment?"], offerSwap: true, openedIndex: nil)
        }
        return BusyResult(toasts: ["Nothing else left in this block. Wait a minute, it frees up."], offerSwap: false, openedIndex: nil)
    }

    /// "Complete" on the exercise screen: a message to confirm when sets are unlogged.
    public func completeExercisePrompt() -> String? {
        let orig = liftList()[curIdx()]
        let p = progOf(orig), n = setsOf(orig)
        if let p = p, !p.reps.isEmpty, p.reps.count < n {
            let k = n - p.reps.count
            return "\(k) set\(k > 1 ? "s" : "") not logged. Mark this exercise done anyway?"
        }
        return nil
    }
    public mutating func completeExercise(confirmedPartial: Bool) {
        let orig = liftList()[curIdx()], ex = shownEx(orig)
        if let p = progOf(orig), !p.reps.isEmpty, p.reps.count < setsOf(orig) {
            if !confirmedPartial { return }
            db.active!.entries[ex.id] = Entry(w: p.w, reps: p.reps)
        }
        db.active!.view = "list"
        woReps = nil
    }

    /// Swap sheet choice. `to == nil` returns to the planned lift. Returns the toast.
    public mutating func applySwap(to: String?) -> String {
        let orig = liftList()[curIdx()]
        if let to = to, !to.isEmpty { db.active!.swaps[orig.id] = to } else { db.active!.swaps[orig.id] = nil }
        db.active!.idx = curIdx()
        if let to = to, !to.isEmpty { return "Swapped to \(Fmt.cleanN(exById(to)?.n ?? to))" }
        return "Back to the planned lift"
    }

    public mutating func toggleLighterDay() -> String {
        db.active!.lowEnergy = !(db.active!.lowEnergy ?? false)
        return db.active!.lowEnergy! ? "Lighter day on" : "Lighter day off"
    }

    public mutating func discardWorkout() { db.active = nil; rest = nil }

    /// The jumps warm-up screen's "Done · start lifting".
    public mutating func completeJumps(sets: [String: Int]) -> String {
        guard let A = db.active else { return "" }
        db.active!.jumpsSeen = 1
        for b in plan[A.day]?.blocks ?? [] where Engine.isWarmUp(b.t) {
            for ex in b.items where (sets[ex.id] ?? 0) > 0 {
                db.active!.entries[ex.id] = Entry(w: 0, reps: Array(repeating: ex.r.map(Double.init), count: sets[ex.id]!))
            }
        }
        logCardio("jumps", CardioEntry(date: "", type: "", landings: Double(Config.landingsPerJumpDay)))
        return "Jumps logged"
    }
    public mutating func skipJumps() { db.active?.jumpsSeen = 1 }

    // MARK: finishing (app.js endSession)

    /// `endSession()` pre-checks: what the web asks with `confirm()`.
    public func endSessionPrompt() -> Prompt? {
        guard let A = db.active else { return nil }
        if A.entries.isEmpty { return Prompt(kind: .discard, message: "Nothing logged yet. Discard this workout?") }
        let missing = requiredItems(A.day).filter { !isLogged($0) }.count
        if missing > 0 { return Prompt(kind: .finish, message: "\(missing) main lift\(missing > 1 ? "s" : "") not logged. Finish anyway?") }
        return nil
    }

    /// `endSession()` once confirmed: progression rules, history entry, celebration.
    public mutating func endSession() -> EndResult {
        guard let A = db.active else { return EndResult(discarded: true) }
        let ids = A.entries.keys
        if ids.isEmpty { db.active = nil; rest = nil; return EndResult(discarded: true) }
        var ups: [String] = [], holds: [String] = []
        for id in ids {
            guard let ex = exById(id), let e = A.entries[id] else { continue }
            let hit = !e.reps.isEmpty && e.reps.allSatisfy { r in
                guard let need = ex.r else { return false }
                return (r ?? 0) >= Double(need)
            }
            let held = (db.holds[id] ?? 0) != 0 || (A.lowEnergy ?? false)
            let up = hit && (ex.inc ?? 0) != 0 && !held
            db.next[id] = up ? progressedWeight(ex, e.w) : e.w
            if up { ups.append(id) } else { holds.append(id) }
        }
        var vol = 0.0
        for id in ids { vol += volOf(id, A.entries[id]!.w, A.entries[id]!.reps) }
        let min = max(1, jsRound((nowMs - (A.started ?? nowMs)) / 60_000))
        db.history.append(Session(date: A.date, day: A.day, vol: jsRound(vol), entries: A.entries,
                                  lowEnergy: A.lowEnergy ?? false, min: min, swaps: A.swaps))
        celebration = Celebration(idx: db.history.count - 1, ups: ups, holds: holds, low: A.lowEnergy ?? false)
        db.active = nil
        rest = nil
        return EndResult(discarded: false)
    }

    /// The numbers on the Workout complete screen.
    public func sessionSummary(_ c: Celebration) -> SessionSummary? {
        guard c.idx >= 0, c.idx < db.history.count else { return nil }
        let s = db.history[c.idx]
        let req = requiredItems(s.day), reqIds = Set(req.map(\.id))
        let sw = s.swaps ?? [:]
        func origOf(_ id: String) -> String { sw.keys.sorted().first { sw[$0] == id } ?? id }
        let wi = warmIds(s.day)
        let mainN = s.entries.keys.filter { reqIds.contains(origOf($0)) }.count
        let bonusN = s.entries.keys.filter { !wi.contains($0) }.count - mainN
        let rows: [SummaryRow] = s.entries.keys.filter { id in
            let e = exById(id)
            return (e != nil && !e!.isBodyweight) || s.entries[id]!.w != 0
        }.map { id in
            let ex = exById(id) ?? Ex(id: id, n: id), e = s.entries[id]!, up = c.ups.contains(id)
            let need = (!up && (ex.r ?? 0) != 0) ? e.reps.reduce(0.0) { $0 + max(0, Double(ex.r!) - ($1 ?? 0)) } : 0
            let unlock = (!up && !c.low && need > 0 && (ex.inc ?? 0) != 0) ? progressedWeight(ex, e.w) : nil
            return SummaryRow(id: id, up: up, next: db.next[id], need: need, unlocks: unlock)
        }
        var cmp: SummaryCompare?
        if let prev = db.history.prefix(c.idx).reversed().first(where: { $0.day == s.day }) {
            let ids = s.entries.keys.filter { prev.entries[$0] != nil }
            if !ids.isEmpty {
                func v(_ id: String) -> Double { volOf(id, s.entries[id]!.w, s.entries[id]!.reps) }
                func pv(_ id: String) -> Double { volOf(id, prev.entries[id]!.w, prev.entries[id]!.reps) }
                let tot = ids.reduce(0.0) { $0 + v($1) }, ptot = ids.reduce(0.0) { $0 + pv($1) }
                let pct = ptot != 0 ? jsRound((tot - ptot) / ptot * 100) : 0
                cmp = SummaryCompare(prevDate: prev.date, pct: pct, items: ids.map { id in
                    let a = v(id), b = pv(id)
                    return .init(id: id, a: a, b: b, p: b != 0 ? jsRound((a - b) / b * 100) : 0)
                })
            }
        }
        return SessionSummary(mainN: mainN, bonusN: bonusN, reqCount: req.count, rows: rows, compare: cmp)
    }
}
