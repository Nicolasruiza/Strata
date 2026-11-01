import Foundation

public struct LastEntry: Codable, Equatable {
    public var w: Double
    public var reps: [Double?]
    public var date: String
}

public struct Gate: Codable, Equatable {
    public var ok: Bool
    public var hard: Bool?
    /// Markdown: `**bold**` where the web used `<b>`.
    public var msg: String
}

extension Engine {
    // MARK: load progression (core.js lastOf … wOf)

    /// `lastOf(id)`: the most recent logged entry for a lift.
    public func lastOf(_ id: String) -> LastEntry? {
        for h in db.history.reversed() {
            if let e = h.entries[id] { return LastEntry(w: e.w, reps: e.reps, date: h.date) }
        }
        return nil
    }

    static let inverseLoadIds: Set<String> = ["alt_assist_pullup", "alt_assist_pullup2"]
    public func inverseLoad(_ ex: Ex?) -> Bool { ex.map { Engine.inverseLoadIds.contains($0.id) } ?? false }

    /// `progressedWeight`: assisted lifts get lighter as you progress.
    public func progressedWeight(_ ex: Ex, _ w: Double) -> Double {
        inverseLoad(ex) ? max(0, w - (ex.inc ?? 0)) : w + (ex.inc ?? 0)
    }

    /// `wOf(ex)`: today's target weight. Also repairs a target saved by the old assisted-pull-up bug.
    public mutating func wOf(_ ex: Ex) -> Double {
        let next = db.next[ex.id]
        if inverseLoad(ex), let n = next, (ex.inc ?? 0) != 0, let l = lastOf(ex.id), n == l.w + ex.inc! {
            let fixed = max(0, l.w - ex.inc!)
            db.next[ex.id] = fixed
            return fixed
        }
        return next ?? ex.w ?? 0
    }

    /// `loEnergyW`: 85% of the weight, floored to a multiple of 5.
    public func loEnergyW(_ w: Double) -> Double {
        if w == 0 { return 0 }
        return max(0, (w * Config.lighterDayWeightFrac / Config.weightStep).rounded(.down) * Config.weightStep)
    }

    /// `volOf`: pounds moved; per-side dumbbells and dual cables move 2× the logged weight.
    public func volOf(_ id: String, _ w: Double, _ reps: [Double?]) -> Double {
        let ex = exById(id)
        let f = (ex?.mult ?? 1) * ((ex?.isEach ?? false) ? 2 : 1)
        if Fmt.isSec(ex ?? Ex(id: id, n: "")) { return 0 }
        return reps.reduce(0) { $0 + (($1 ?? 0) * w * f) }
    }

    // MARK: sessions and blocks

    /// `isOptionalBlock`: bonus, warm-up and legacy isolation blocks never gate a session.
    public static func isOptionalBlock(_ t: String) -> Bool {
        t.range(of: "^(bonus|warm-up|isolation)", options: [.regularExpression, .caseInsensitive]) != nil
    }
    static func isWarmUp(_ t: String) -> Bool { t.range(of: "^warm-up", options: [.regularExpression, .caseInsensitive]) != nil }
    static func isWarm(_ t: String) -> Bool { t.range(of: "^warm", options: [.regularExpression, .caseInsensitive]) != nil }

    public func requiredItems(_ day: Int) -> [Ex] {
        (plan[day]?.blocks ?? []).filter { !Engine.isOptionalBlock($0.t) }.flatMap(\.items)
    }
    public func sessionItems(_ day: Int, lowEnergy: Bool) -> [Ex] {
        (plan[day]?.blocks ?? []).filter { !(lowEnergy && Engine.isOptionalBlock($0.t)) }.flatMap(\.items)
    }
    /// `minutesFor`
    public func minutesFor(_ day: Int) -> Double {
        jsRound(Double(requiredItems(day).count) * Config.minutesPerLift / 5) * 5
    }
    public func isLegs(_ day: Int) -> Bool {
        (plan[day]?.name ?? "").range(of: "^legs", options: [.regularExpression, .caseInsensitive]) != nil
    }

    // MARK: weekly volume, holds and injuries

    /// `weeklySets(extraSkip)`: sets per area; held / injured lifts count zero.
    public func weeklySets(skip: [String] = []) -> [String: Double] {
        let skipSet = Set(skip), inj = injuredIds
        var acc: [String: Double] = [:]
        catalog.areas.forEach { acc[$0] = 0 }
        for d in days {
            for b in plan[d]!.blocks {
                for ex in b.items {
                    if skipSet.contains(ex.id) || inj.contains(ex.id) { continue }
                    let m = meta(ex.id), n = Double(ex.setCount)
                    for a in m.p where acc[a] != nil { acc[a]! += n }
                    for a in m.s ?? [] where acc[a] != nil { acc[a]! += n / 2 }
                }
            }
        }
        return acc
    }

    /// `patternsLost(ids)`
    public func patternsLost(_ ids: [String]) -> [String] {
        let skip = Set(ids), inj = injuredIds
        var order: [String] = [], all: [String: Int] = [:], live: [String: Int] = [:]
        for d in days {
            for b in plan[d]!.blocks {
                for ex in b.items {
                    let p = meta(ex.id).pat
                    if p.isEmpty { continue }
                    if all[p] == nil { order.append(p) }
                    all[p, default: 0] += 1
                    if !skip.contains(ex.id) && !inj.contains(ex.id) { live[p, default: 0] += 1 }
                }
            }
        }
        return order.filter { (live[$0] ?? 0) == 0 }
    }

    /// `costOf(ids)`: what a hold would cost, stated before it is applied.
    public func costOf(_ ids: [String]) -> InjuryCost {
        let before = weeklySets(), after = weeklySets(skip: ids)
        let drops = catalog.areas
            .filter { after[$0]! < before[$0]! - 0.01 }
            .map { InjuryDrop(area: $0, from: before[$0]!, to: after[$0]!) }
            .stableSorted { ($0.to - $0.from) < ($1.to - $1.from) }
        return InjuryCost(drops: drops, lost: patternsLost(ids))
    }

    /// The confirm text shown before flagging an injury (app.js `ds.inj` handler).
    public func injuryPrompt(_ key: String) -> String {
        let ids = PlanBuilder.idsForInjury(key, plan), c = costOf(ids)
        let label = (catalog.injuries[key]?.label ?? key).lowercased()
        var msg = "Flag \(label)? \(ids.count) lift\(ids.count == 1 ? "" : "s") go on hold."
        if !c.drops.isEmpty {
            msg += " " + c.drops.prefix(3).map { "\($0.area) \(Fmt.fmtSets($0.from))→\(Fmt.fmtSets($0.to))" }.joined(separator: ", ") + " sets/week."
        }
        return msg
    }

    /// `applyInjury(key)`: returns the toast, or nil when nothing was done.
    @discardableResult
    public mutating func applyInjury(_ key: String) -> String? {
        guard let def = catalog.injuries[key], !db.injuries.contains(where: { $0.key == key }) else { return nil }
        let ids = PlanBuilder.idsForInjury(key, plan)
        let c = costOf(ids)
        let added = ids.filter { (db.holds[$0] ?? 0) == 0 }
        db.injuries.append(InjuryRecord(key: key, since: today, ids: ids, added: added, cost: c))
        ids.forEach { db.holds[$0] = 1 }
        setActivePlan()
        return ids.isEmpty
            ? "\(def.label) flagged · nothing in your week loads that"
            : "\(def.label) flagged · \(ids.count) exercise\(ids.count == 1 ? "" : "s") held"
    }

    /// `releaseInjury(key)`
    @discardableResult
    public mutating func releaseInjury(_ key: String) -> String? {
        guard let rec = db.injuries.first(where: { $0.key == key }) else { return nil }
        db.injuries.removeAll { $0.key == key }
        let still = injuredIds
        for id in rec.added ?? rec.ids where !still.contains(id) { db.holds[id] = nil }
        setActivePlan()
        return "\(catalog.injuries[key]?.label ?? key) released · progression resumes"
    }

    // MARK: rotation and the rest-day gate

    /// `nextDay()`
    public func nextDay() -> Int {
        let n = days.count
        if let last = db.history.last, last.day <= n { return (last.day % n) + 1 }
        return 1
    }

    /// `gate()` for rotation day `view`.
    public func gate(view: Int) -> Gate {
        guard let last = db.history.last else { return Gate(ok: true, hard: nil, msg: "First session. Nothing logged yet.") }
        let gap = Dates.dayDiff(last.date, today)
        let name = plan[last.day]?.name ?? ""
        func region(_ d: Int) -> String { isLegs(d) ? "legs" : "upper" }
        if gap == 0 {
            return Gate(ok: false, hard: false, msg: "You already trained **\(name)** today. Two sessions in one day is not more progress, it is less recovery — only override to catch up a missed log.")
        }
        if gap == 1, plan[last.day] != nil, region(last.day) != region(view) {
            return Gate(ok: true, hard: nil, msg: "You trained **\(name)** yesterday, so today's \(region(view) == "legs" ? "legs are" : "upper body is") fresh.")
        }
        if gap == 1 {
            return Gate(ok: false, hard: false, msg: "You trained **\(name)** yesterday. Give the same muscles a day: do the other half, or a walk.")
        }
        return Gate(ok: true, hard: nil, msg: "Last strength session: **\(name)**, \(gap) days ago.")
    }
}
