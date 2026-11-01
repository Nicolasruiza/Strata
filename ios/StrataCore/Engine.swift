import Foundation

public struct RestState: Codable, Equatable {
    public var endAt: Double
    public var total: Double
    public var next: String?
    public var lbl: String
    public var beeped: Bool
}

public struct Celebration: Codable, Equatable {
    public var idx: Int
    public var ups: [String]
    public var holds: [String]
    public var low: Bool
}

/// `W_last`: the cardio block that was just completed.
public struct WLast: Codable, Equatable {
    public var min: Double
    public var act: String
    public var avgHR: Double?
    public var maxHR: Double?
    public var zones: [Double]?
    public var elev: Double?
    public var intervals: Double?
    public var type: String
    public var date: String
    public var health: Bool
}

/// The result of `setActivePlan()`: `PLAN`, `ALL`, `ALT_OF`, `STD`, `QMAP`, `BW`.
public struct ActivePlan: Codable, Equatable {
    public var plan: PlanMap
    public var all: [Ex]
    public var altOf: [String: [Ex]]
    public var std: [String: Double]
    public var qmap: String
    public var bw: Double
}

/// The web's global state (`DB`, `profile`, `PLAN`, the in-memory workout state) as one value.
/// Methods mirror the JS functions; those that change data are `mutating`. Anything the web
/// did with `confirm()` is split into a pure `…Prompt` check plus the confirmed action, and
/// anything it did with `toast()` returns the toast text.
public struct Engine {
    public var profile: Profile
    public var db: AppData
    public var nowMs: Double
    public var tz: TimeZone
    public internal(set) var ap: ActivePlan

    // In-memory workout state (never persisted, as on the web)
    public var rest: RestState?
    public var celebration: Celebration?
    public var woReps: Double?
    public var preLow = false
    public var wLast: WLast?
    public var view = 1

    public init(profile: Profile, db: AppData, nowMs: Double, tz: TimeZone) {
        self.profile = profile; self.db = db; self.nowMs = nowMs; self.tz = tz
        self.ap = PlanBuilder.build(profile: profile, db: db)
    }

    public var catalog: Catalog { .shared }
    public var plan: PlanMap { ap.plan }
    public var today: String { Dates.today(nowMs: nowMs, tz: tz) }
    /// `DAYS()`
    public var days: [Int] { plan.keys.sorted() }
    public func items(_ d: Int) -> [Ex] { (plan[d]?.blocks ?? []).flatMap(\.items) }
    public func meta(_ id: String) -> Concept { catalog.meta(of: id) }

    /// `exById`
    public func exById(_ id: String) -> Ex? { ap.all.first { $0.id == id } ?? catalog.exIndex[id] }

    public mutating func setActivePlan() { ap = PlanBuilder.build(profile: profile, db: db) }

    // MARK: injuries held
    public var injuredIds: Set<String> { PlanBuilder.injuredIds(db) }
}

// MARK: - Plan building (core.js genPlan … setActivePlan)

public enum PlanBuilder {
    static var cat: Catalog { .shared }

    public static func round5(_ v: Double) -> Double { max(0, jsRound(v / Config.weightStep) * Config.weightStep) }

    static func expLevel(_ key: String) -> ExpLevel { cat.exp[key] ?? cat.exp["trained"]! }

    /// `genPlan(bw,exp)`
    public static func genPlan(bw: Double, exp: String) -> PlanMap {
        let e = expLevel(exp)
        var out: PlanMap = [:]
        let src = cat.plans["nr"]!
        for d in src.keys.sorted() {
            let day = src[d]!
            out[d] = PlanDay(name: day.name, short: day.short, blocks: day.blocks.map { b in
                Block(t: b.t, items: b.items.map { ex in
                    var o = ex
                    if !ex.isBodyweight {
                        var w = round5((ex.frac ?? 0) * bw * e.f)
                        if let bar = ex.bar, w < bar { w = bar }
                        o.w = w
                    }
                    if (ex.inc ?? 0) != 0 { o.inc = e.inc ?? ex.inc }
                    return o
                })
            })
        }
        return out
    }

    /// `planFor(p)`
    public static func planFor(_ p: Profile) -> PlanMap {
        if p.plan == "nr" { return cat.plans["nr"]! }
        if p.plan == "sa" { return cat.plans["sa"]! }
        return genPlan(bw: p.bw, exp: p.exp)
    }

    /// `stdFor(p)`
    public static func stdFor(_ p: Profile) -> [String: Double] {
        let frac = p.plan == "sa" ? cat.stdFrac["sa"]! : cat.stdFrac["nr"]!
        return frac.mapValues { $0 * p.bw }
    }

    /// `deriveW(spec)`
    static func deriveW(_ spec: Ex, _ p: Profile) -> Double {
        if spec.isBodyweight { return 0 }
        let e = expLevel(p.exp)
        var w = round5((spec.frac ?? 0) * p.bw * e.f)
        if let bar = spec.bar, w < bar { w = bar }
        return w
    }

    /// `mkEx(spec)`
    static func mkEx(_ spec: Ex, _ p: Profile) -> Ex {
        let e = expLevel(p.exp)
        var o = spec
        o.w = deriveW(spec, p)
        if (spec.inc ?? 0) != 0 { o.inc = e.inc ?? spec.inc }
        return o
    }

    typealias Loc = (d: Int, b: Int, i: Int)

    /// `findByMatch(plan,match)`
    static func findByMatch(_ plan: PlanMap, _ match: String) -> Loc? {
        let m = match.lowercased()
        if m.isEmpty { return nil }
        for d in plan.keys.sorted() {
            for (bi, b) in plan[d]!.blocks.enumerated() {
                for (ii, x) in b.items.enumerated() where x.n.lowercased().contains(m) { return (d, bi, ii) }
            }
        }
        return nil
    }

    /// `appendEx(plan,spec)`
    @discardableResult
    static func appendEx(_ plan: inout PlanMap, _ spec: PlanAddition, _ p: Profile) -> Bool {
        if let f = findByMatch(plan, spec.match) {
            if (spec.primary ?? 0) != 0, f.d == spec.day {
                let bs = plan[spec.day]!.blocks
                if let dest = bs.firstIndex(where: { $0.t == spec.block }), dest != f.b {
                    var x = plan[f.d]!.blocks[f.b].items.remove(at: f.i)
                    x.key = 1
                    plan[spec.day]!.blocks[dest].items.append(x)
                }
            }
            return false
        }
        let bs = plan[spec.day]!.blocks
        let target = bs.firstIndex(where: { $0.t == spec.block }) ?? (bs.count - 1)
        plan[spec.day]!.blocks[target].items.append(mkEx(spec.ex, p))
        return true
    }

    /// `applyBump(plan,area)`: two extra sets on the priority pattern; core is sets-only.
    static func applyBump(_ plan: inout PlanMap, _ area: String) {
        if area == "core" {
            for d in plan.keys.sorted() {
                outer: for bi in plan[d]!.blocks.indices {
                    if let ii = plan[d]!.blocks[bi].items.firstIndex(where: { cat.meta(of: $0.id).p.contains("core") }) {
                        plan[d]!.blocks[bi].items[ii].sets = 5
                        break outer
                    }
                }
            }
            return
        }
        var all: [Loc] = []
        for d in plan.keys.sorted() { for (bi, b) in plan[d]!.blocks.enumerated() { for ii in b.items.indices { all.append((d, bi, ii)) } } }
        var target: Loc?
        if let f = cat.focus[area], let bump = f.bump {
            for l in all where cat.conceptOf[plan[l.d]!.blocks[l.b].items[l.i].id] == bump { target = l }
        }
        if target == nil {
            let hits = all.filter { cat.meta(of: plan[$0.d]!.blocks[$0.b].items[$0.i].id).p.contains(area) }
            target = hits.last
        }
        if let t = target {
            let cur = plan[t.d]!.blocks[t.b].items[t.i].sets ?? 0
            plan[t.d]!.blocks[t.b].items[t.i].sets = (cur != 0 ? cur : Config.defaultSets) + 2
        }
    }

    /// `idsForInjury(key,plan)`
    public static func idsForInjury(_ key: String, _ plan: PlanMap) -> [String] {
        guard let def = cat.injuries[key] else { return [] }
        var out: [String] = []
        for d in plan.keys.sorted() {
            for b in plan[d]!.blocks {
                for x in b.items where cat.meta(of: x.id).load.contains(where: { def.loads.contains($0) }) {
                    if !out.contains(x.id) { out.append(x.id) }
                }
            }
        }
        return out
    }

    /// `injuredIds()`
    static func injuredIds(_ db: AppData) -> Set<String> {
        var s = Set<String>()
        for i in db.injuries { i.ids.forEach { s.insert($0) } }
        return s
    }

    /// `clonePlan(planFor(profile))` with injury substitutes, focus additions and holds applied.
    public static func build(profile: Profile, db: AppData) -> ActivePlan {
        var base = planFor(profile)
        for i in db.injuries {
            if let def = cat.injuries[i.key] { def.subs.forEach { appendEx(&base, $0, profile) } }
        }
        if let key = db.focus, let f = cat.focus[key] {
            f.add.forEach { appendEx(&base, $0, profile) }
            applyBump(&base, key)
        }
        let inj = injuredIds(db)
        for d in base.keys.sorted() {
            for bi in base[d]!.blocks.indices {
                for ii in base[d]!.blocks[bi].items.indices where inj.contains(base[d]!.blocks[bi].items[ii].id) {
                    base[d]!.blocks[bi].items[ii].injured = 1
                }
            }
        }
        let list = base.keys.sorted().flatMap { d in base[d]!.blocks.flatMap(\.items) }
        var alts: [Ex] = []
        for x in list {
            for a in cat.meta(of: x.id).alts where !alts.contains(where: { $0.id == a.id }) {
                var spec = a
                spec.r = x.r
                alts.append(mkEx(spec, profile))
            }
        }
        var altOf: [String: [Ex]] = [:]
        for x in list {
            altOf[x.id] = cat.meta(of: x.id).alts.compactMap { a in alts.first { $0.id == a.id } }
        }
        return ActivePlan(plan: base, all: list + alts, altOf: altOf, std: stdFor(profile),
                          qmap: profile.plan == "sa" ? "sa" : "nr", bw: profile.bw)
    }
}
