import Foundation

// MARK: - Exercises and plans (core.js PLAN_*, CONCEPT, FOCUS, INJURIES)

/// One exercise definition. Flags (`key`, `each`, `bw`, `plates`, `injured`) stay `Int?`
/// (the web writes 1) so encoded plans are identical to the JS objects.
public struct Ex: Codable, Equatable {
    public var id: String
    public var n: String
    public var r: Int?
    public var w: Double?
    public var inc: Double?
    public var key: Int?
    public var each: Int?
    public var bw: Int?
    public var plates: Int?
    public var injured: Int?
    public var bar: Double?
    public var frac: Double?
    public var mult: Double?
    public var sets: Int?

    public init(id: String, n: String, r: Int? = nil, w: Double? = nil, inc: Double? = nil, key: Int? = nil, each: Int? = nil,
                bw: Int? = nil, plates: Int? = nil, injured: Int? = nil, bar: Double? = nil, frac: Double? = nil, mult: Double? = nil, sets: Int? = nil) {
        self.id = id; self.n = n; self.r = r; self.w = w; self.inc = inc; self.key = key; self.each = each
        self.bw = bw; self.plates = plates; self.injured = injured; self.bar = bar; self.frac = frac; self.mult = mult; self.sets = sets
    }

    public var isBodyweight: Bool { (bw ?? 0) != 0 }
    public var isEach: Bool { (each ?? 0) != 0 }
    public var isKey: Bool { (key ?? 0) != 0 }
    public var hasPlates: Bool { (plates ?? 0) != 0 }
    public var isInjured: Bool { (injured ?? 0) != 0 }
    /// `ex.sets||3`
    public var setCount: Int { (sets ?? 0) != 0 ? sets! : Config.defaultSets }
}

public struct Block: Codable, Equatable {
    public var t: String
    public var items: [Ex]
}

public struct PlanDay: Codable, Equatable {
    public var name: String
    public var short: String
    public var blocks: [Block]
}

public typealias PlanMap = [Int: PlanDay]

public struct Concept: Codable, Equatable {
    public var p: [String]
    public var s: [String]?
    public var pat: String
    public var load: [String]
    public var alts: [Ex]
}

public struct PlanAddition: Codable, Equatable {
    public var day: Int
    public var block: String
    public var match: String
    public var primary: Int?
    public var ex: Ex
}

public struct FocusDef: Codable, Equatable {
    public var label: String
    public var target: Int
    public var bump: String?
    public var note: String
    public var add: [PlanAddition]
}

public struct InjuryDef: Codable, Equatable {
    public var label: String
    public var loads: [String]
    public var why: String
    public var subs: [PlanAddition]
}

public struct ExpLevel: Codable, Equatable {
    public var f: Double
    public var inc: Double?
    public var label: String
}

public struct HomePlan: Codable, Equatable {
    public var name: String
    public var min: Int
    public var ring: String
    public var moves: [[String]]
}

public struct CardioActivityDef: Codable, Equatable {
    public var n: String
    public var out: Bool
}

// MARK: - Profile (strata:me)

public struct Profile: Codable, Equatable {
    public var id: String
    public var name: String
    public var initials: String
    public var gender: String?
    public var plan: String
    public var bw: Double
    public var exp: String

    public init(id: String = "me", name: String, initials: String, gender: String?, plan: String, bw: Double, exp: String) {
        self.id = id; self.name = name; self.initials = initials
        self.gender = gender; self.plan = plan; self.bw = bw; self.exp = exp
    }
}

// MARK: - DB (same field names as the web `DB`, so a web export imports unchanged)

public struct Entry: Codable, Equatable {
    public var w: Double
    public var reps: [Double?]
    public init(w: Double, reps: [Double?]) { self.w = w; self.reps = reps }
}

public struct Session: Codable, Equatable {
    public var date: String
    public var day: Int
    public var vol: Double?
    public var entries: OrderedDict<Entry>
    public var lowEnergy: Bool?
    public var min: Double?
    public var swaps: [String: String]?

    enum CodingKeys: String, CodingKey { case date, day, vol, entries, lowEnergy, min, swaps }
    public init(date: String, day: Int, vol: Double?, entries: OrderedDict<Entry>, lowEnergy: Bool?, min: Double?, swaps: [String: String]?) {
        self.date = date; self.day = day; self.vol = vol; self.entries = entries
        self.lowEnergy = lowEnergy; self.min = min; self.swaps = swaps
    }
    public init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        date = try c.decode(String.self, forKey: .date)
        day = try c.decode(Int.self, forKey: .day)
        vol = try c.decodeIfPresent(Double.self, forKey: .vol)
        entries = try c.decodeIfPresent(OrderedDict<Entry>.self, forKey: .entries) ?? OrderedDict()
        lowEnergy = try c.decodeFlexBool(forKey: .lowEnergy)
        min = try c.decodeIfPresent(Double.self, forKey: .min)
        swaps = try c.decodeIfPresent([String: String].self, forKey: .swaps)
    }
}

public struct Prog: Codable, Equatable {
    public var w: Double
    public var reps: [Double?]
    public init(w: Double, reps: [Double?]) { self.w = w; self.reps = reps }
}

public struct WarmSet: Codable, Equatable {
    public var w: Double
    public var r: Double
    public var done: Bool
}

public struct ActiveWorkout: Codable, Equatable {
    public var day: Int
    public var date: String
    public var started: Double?
    public var entries: OrderedDict<Entry>
    public var lowEnergy: Bool?
    public var swaps: [String: String]
    public var prog: [String: Prog]
    public var idx: Int?
    public var view: String?
    public var exT: [String: Double]?
    public var extra: [String: Int]?
    public var warm: [String: [WarmSet]]?
    public var busy: [String: Double]?
    public var cd: Int?
    public var jumpsSeen: Int?
    /// iOS: sets logged so far on the jumps warm-up (pogo, box, plan warm-up moves), so leaving and coming back keeps them.
    public var jumps: [String: Int]?

    enum CodingKeys: String, CodingKey {
        case day, date, started, entries, lowEnergy, swaps, prog, idx, view, exT, extra, warm, busy, cd, jumpsSeen, jumps
    }
    public init(day: Int, date: String, started: Double?, entries: OrderedDict<Entry> = OrderedDict(), lowEnergy: Bool?, swaps: [String: String] = [:], prog: [String: Prog] = [:], idx: Int? = 0) {
        self.day = day; self.date = date; self.started = started; self.entries = entries
        self.lowEnergy = lowEnergy; self.swaps = swaps; self.prog = prog; self.idx = idx
    }
    public init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        day = try c.decode(Int.self, forKey: .day)
        date = try c.decode(String.self, forKey: .date)
        started = try c.decodeIfPresent(Double.self, forKey: .started)
        entries = try c.decodeIfPresent(OrderedDict<Entry>.self, forKey: .entries) ?? OrderedDict()
        lowEnergy = try c.decodeFlexBool(forKey: .lowEnergy)
        swaps = try c.decodeIfPresent([String: String].self, forKey: .swaps) ?? [:]
        prog = try c.decodeIfPresent([String: Prog].self, forKey: .prog) ?? [:]
        idx = try c.decodeIfPresent(Int.self, forKey: .idx)
        view = try c.decodeIfPresent(String.self, forKey: .view)
        exT = try c.decodeIfPresent([String: Double].self, forKey: .exT)
        extra = try c.decodeIfPresent([String: Int].self, forKey: .extra)
        warm = try c.decodeIfPresent([String: [WarmSet]].self, forKey: .warm)
        busy = try c.decodeIfPresent([String: Double].self, forKey: .busy)
        cd = try c.decodeIfPresent(Int.self, forKey: .cd)
        jumpsSeen = try c.decodeIfPresent(Int.self, forKey: .jumpsSeen)
        jumps = try c.decodeIfPresent([String: Int].self, forKey: .jumps)
    }
}

public struct CardioEntry: Codable, Equatable {
    public var date: String
    public var type: String
    public var min: Double?
    public var act: String?
    public var avgHR: Double?
    public var maxHR: Double?
    public var zones: [Double]?
    public var elev: Double?
    public var intervals: Double?
    public var steps: Double?
    public var landings: Double?
    public var home: Int?
    public var focus: String?

    public init(date: String, type: String, min: Double? = nil, act: String? = nil, avgHR: Double? = nil, maxHR: Double? = nil, zones: [Double]? = nil, elev: Double? = nil, intervals: Double? = nil, steps: Double? = nil, landings: Double? = nil, home: Int? = nil, focus: String? = nil) {
        self.date = date; self.type = type; self.min = min; self.act = act; self.avgHR = avgHR
        self.maxHR = maxHR; self.zones = zones; self.elev = elev; self.intervals = intervals
        self.steps = steps; self.landings = landings; self.home = home; self.focus = focus
    }
}

public struct Waist: Codable, Equatable {
    public var date: String
    public var cm: Double
}

public struct Skip: Codable, Equatable {
    public var why: String
    public var slot: String
    public var key: String
    public var day: Int?
    public var done: Int?
}

public struct InjuryDrop: Codable, Equatable {
    public var area: String
    public var from: Double
    public var to: Double
}

public struct InjuryCost: Codable, Equatable {
    public var drops: [InjuryDrop]
    public var lost: [String]
}

public struct InjuryRecord: Codable, Equatable {
    public var key: String
    public var since: String
    public var ids: [String]
    public var added: [String]?
    public var cost: InjuryCost?
}

public struct Sample: Codable, Equatable {
    public var t: Double
    public var hr: Double?
    public var alt: Double?
    public init(t: Double, hr: Double?, alt: Double?) { self.t = t; self.hr = hr; self.alt = alt }
}

/// `DB.live`: the running cardio session.
public struct LiveCardio: Codable, Equatable {
    public var act: String
    public var mode: String
    public var n: Int?
    public var slot: String?
    public var started: Double
    public var date: String
    public var samples: [Sample]?
}

public struct AppData: Codable, Equatable {
    public var next: [String: Double] = [:]
    public var history: [Session] = []
    public var active: ActiveWorkout?
    public var holds: [String: Int] = [:]
    public var cycleStarts: [String] = []
    public var focus: String?
    public var injuries: [InjuryRecord] = []
    public var cycleAnchor: String?
    public var cardio: [CardioEntry] = []
    public var age: Double?
    public var officeDays: [Int]?
    public var rcOffice: Bool?
    public var waist: [Waist]?
    public var skips: [String: Skip]?
    public var live: LiveCardio?
    /// Daily Mobility check-offs (iOS only; the web ignores it).
    public var mobility: [MobilityDone]?

    enum CodingKeys: String, CodingKey {
        case next, history, active, holds, cycleStarts, focus, injuries, cycleAnchor, cardio, age
        case officeDays, rcOffice, waist, skips, live, mobility
    }

    public init() {}

    /// `freshDB()`: `defaultDB('x')` with no holds.
    public static func fresh() -> AppData { AppData() }

    /// `defaultDB(planKey)`: the original seed hold on the Romanian deadlift for the "nr" plan.
    public static func `default`(planKey: String) -> AppData {
        var d = AppData()
        if planKey == "nr" { d.holds = ["rdl": 1] }
        return d
    }

    public init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        next = try c.decodeIfPresent([String: Double].self, forKey: .next) ?? [:]
        history = try c.decodeIfPresent([Session].self, forKey: .history) ?? []
        active = try c.decodeIfPresent(ActiveWorkout.self, forKey: .active)
        holds = try c.decodeIfPresent([String: Int].self, forKey: .holds) ?? [:]
        cycleStarts = try c.decodeIfPresent([String].self, forKey: .cycleStarts) ?? []
        focus = try c.decodeIfPresent(String.self, forKey: .focus)
        injuries = try c.decodeIfPresent([InjuryRecord].self, forKey: .injuries) ?? []
        cycleAnchor = try c.decodeIfPresent(String.self, forKey: .cycleAnchor)
        cardio = try c.decodeIfPresent([CardioEntry].self, forKey: .cardio) ?? []
        age = try c.decodeIfPresent(Double.self, forKey: .age)
        officeDays = try c.decodeIfPresent([Int].self, forKey: .officeDays)
        rcOffice = try c.decodeFlexBool(forKey: .rcOffice)
        waist = try c.decodeIfPresent([Waist].self, forKey: .waist)
        skips = try c.decodeIfPresent([String: Skip].self, forKey: .skips)
        live = try c.decodeIfPresent(LiveCardio.self, forKey: .live)
        mobility = try c.decodeIfPresent([MobilityDone].self, forKey: .mobility)
        // `demoSensors` is a web testing switch: read nothing, write nothing.
    }
}


/// One exercise checked off in one Daily Mobility session on one local date.
public struct MobilityDone: Codable, Equatable {
    public var date: String
    public var session: String
    public var ex: String
    /// Sets finished so far. Nil (older saves) means every set was done.
    public var sets: Int?
    public init(date: String, session: String, ex: String, sets: Int? = nil) { self.date = date; self.session = session; self.ex = ex; self.sets = sets }
}
