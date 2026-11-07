import Foundation

public struct WeekStats: Codable, Equatable {
    public var m: Int, mt: Int, h: Int, ht: Int, b: Int, bt: Int
    public var closed: [Bool]
    public var all: Bool
}

public struct LiftSlot: Codable, Equatable {
    public var day: Int?
    public var status: String
}

public struct NextCard: Codable, Equatable {
    public var col: String        // "m" or "h"
    public var label: String
    public var name: String
    public var sub: String
}

public struct HistoryItem: Codable, Equatable {
    public var date: String
    public var kind: String       // "lift" or the cardio type
    public var index: Int         // index into history (lift) or cardio
}

public struct ProgressPoint: Codable, Equatable {
    public var l: String
    public var y: Double
    public init(l: String, y: Double) { self.l = l; self.y = y }
}

public struct TopSet: Codable, Equatable {
    public var d: String
    public var v: Double
}

extension Engine {
    // MARK: week plan (app.js)

    public static let wdOrder = [1, 2, 3, 4, 5, 6, 0]

    public func officeDays() -> [Int] {
        if let o = db.officeDays { return o }
        return (db.rcOffice ?? false) ? [2, 4] : []
    }

    /// `weekPlan()`: weekday (0 = Sun) → slot.
    public func weekPlan() -> [Int: String] {
        var w: [Int: String] = [1: "lift", 2: "z2", 3: "lift", 4: "vo2", 5: "lift", 6: "lift", 0: "walk"]
        let off = officeDays()
        if !off.isEmpty {
            var moved = false
            for d in off {
                if w[d] == "lift" { continue }
                if w[d] == "vo2" { moved = true }
                w[d] = "office"
            }
            for d in Array(w.keys) where w[d] == "z2" { w[d] = "rest" }
            if moved { w[0] = "vo2" }
        }
        return w
    }

    public var heartSlots: Set<String> { Set(catalog.heart) }

    public func cardioOn(_ date: String, _ type: String) -> CardioEntry? { db.cardio.first { $0.date == date && $0.type == type } }
    public func liftedOn(_ date: String) -> Session? { db.history.first { $0.date == date } }
    public func skipOn(_ date: String) -> Skip? { db.skips?[date] }

    /// Applies HealthKit daily totals to the existing office-day step records.
    /// Other weekdays are deliberately ignored because an `office` entry also closes a heart slot.
    @discardableResult
    public mutating func syncHealthSteps(_ totals: [String: Int]) -> Bool {
        let plan = weekPlan()
        var changed = false
        for (date, steps) in totals where date <= today && steps > 0 && plan[Dates.weekday(date)] == "office" {
            if let index = db.cardio.firstIndex(where: { $0.date == date && $0.type == "office" }) {
                let value = Double(steps)
                if db.cardio[index].steps != value {
                    db.cardio[index].steps = value
                    changed = true
                }
            } else {
                logCardio("office", CardioEntry(date: "", type: "", steps: Double(steps)), date: date)
                changed = true
            }
        }
        return changed
    }

    // MARK: rings

    public func weekStats(_ mon: String) -> WeekStats {
        let ds = Dates.weekDates(mon)
        let mt = Config.RingGoals.muscle, ht = Config.RingGoals.heart, bt = Config.RingGoals.bone
        let m = Set(db.history.filter { ds.contains($0.date) }.map(\.date)).count
        let hk = Set(db.cardio.filter { c in
            ds.contains(c.date) && c.type != "jumps" && c.type != "home"
                && !(c.type == "cardio" && (c.min ?? 0) < Config.workout.shortCardioMin)
        }.map { $0.date + $0.type })
        let h = hk.count
        let b = Set(db.cardio.filter { ds.contains($0.date) && $0.type == "jumps" }.map(\.date)).count
        return WeekStats(m: m, mt: mt, h: h, ht: ht, b: b, bt: bt, closed: [m >= mt, h >= ht, b >= bt], all: m >= mt && h >= ht && b >= bt)
    }

    /// `streak()`: full weeks (all three rings closed) before this one.
    public func streak() -> Int {
        var n = 0
        var mon = Dates.addDays(Dates.mondayOf(today), -7)
        let dates = db.history.map(\.date) + db.cardio.map(\.date)
        guard let first = dates.sorted().first else { return 0 }
        while mon >= Dates.mondayOf(first) {
            if weekStats(mon).all { n += 1; mon = Dates.addDays(mon, -7) } else { break }
        }
        return n
    }

    /// `liftSlots(mon)`: each lift slot this week gets its own workout. Skipped days keep the
    /// rotation where it was.
    public func liftSlots(_ mon: String) -> [Int: LiftSlot] {
        let ds = Dates.weekDates(mon), wp = weekPlan(), t = today, n = days.count
        var out: [Int: LiftSlot] = [:]
        var next = nextDay()
        for (i, w) in Engine.wdOrder.enumerated() {
            if wp[w] != "lift" { continue }
            let d = ds[i]
            if let h = liftedOn(d), plan[h.day] != nil { out[w] = LiftSlot(day: h.day, status: "done"); continue }
            if skipOn(d) != nil { out[w] = LiftSlot(day: nil, status: "skipped"); continue }
            if d < t { out[w] = LiftSlot(day: nil, status: "missed"); continue }
            if d == t, let a = db.active { out[w] = LiftSlot(day: a.day, status: "live"); next = (a.day % n) + 1; continue }
            out[w] = LiftSlot(day: next, status: "planned")
            next = (next % n) + 1
        }
        return out
    }

    public func slotDone(_ slot: String, _ date: String, _ mon: String) -> Bool {
        if slot == "lift" { return liftedOn(date) != nil }
        if slot == "office" { return cardioOn(date, "office") != nil }
        if slot == "rest" { return false }
        guard let t = catalog.ctype[slot] else { return false }
        return Dates.weekDates(mon).contains { cardioOn($0, t) != nil }
    }

    // MARK: copy built from the numbers

    public func ringsLine(_ st: WeekStats) -> String {
        if st.all { return "All three layers done for the week." }
        var left: [String] = []
        if !st.closed[0] { left.append("\(st.mt - st.m) more lift\(st.mt - st.m > 1 ? "s" : "")") }
        if !st.closed[1] { left.append("\(st.ht - st.h) heart session\(st.ht - st.h > 1 ? "s" : "")") }
        if !st.closed[2] { left.append("\(st.bt - st.b) jump day") }
        return "Still to go: \(left.joined(separator: ", "))."
    }

    /// The headline under the rings on Today.
    public func weekHeadline(_ st: WeekStats) -> String {
        if st.all { return "Full week done. Every layer got its dose." }
        var s = ""
        let lifts = st.mt - st.m, heart = st.ht - st.h, jumps = st.bt - st.b
        if lifts > 0 { s += "\(lifts) lift\(lifts > 1 ? "s" : "")" }
        if heart > 0 { s += "\(lifts > 0 ? ", " : "")\(heart) heart session\(heart > 1 ? "s" : "")" }
        if jumps > 0 { s += "\((lifts > 0 || heart > 0) ? ", " : "")\(jumps) jump day\(jumps > 1 ? "s" : "")" }
        return s + " left this week."
    }

    /// `nextCard(fromDate)` as data.
    public func nextCard(from t: String) -> NextCard? {
        let mon = Dates.mondayOf(t), wp = weekPlan(), slots = liftSlots(mon)
        for i in 1...7 {
            let d = Dates.addDays(t, i), w = Dates.weekday(d)
            guard let s = wp[w], s != "rest" else { continue }
            let name: String, sub: String, col: String
            if s == "lift" {
                let sl = d < Dates.addDays(mon, 7) ? slots[w] : nil
                let day = sl?.day ?? nextDay()
                name = plan[day]?.name ?? ""
                sub = "\(requiredItems(day).count) main lifts · ~\(jsNum(minutesFor(day))) min"
                col = "m"
            } else {
                if s != "office", let ct = catalog.ctype[s], Dates.weekDates(Dates.mondayOf(d)).contains(where: { cardioOn($0, ct) != nil }) { continue }
                name = catalog.slotName[s] ?? s
                sub = s == "office" ? "10,000 steps" : s == "vo2" ? "~\(rcMinutes(Config.Intervals.fullCount)) min on the treadmill" : "Easy pace"
                col = "h"
            }
            return NextCard(col: col, label: "Next · \(i == 1 ? "Tomorrow" : catalog.wdLong[String(w)] ?? "")", name: name, sub: sub)
        }
        return nil
    }

    // MARK: history and progress

    public func warmIds(_ day: Int) -> Set<String> {
        guard let p = plan[day] else { return [] }
        return Set(p.blocks.filter { Engine.isWarmUp($0.t) }.flatMap { $0.items.map(\.id) })
    }
    public func exCount(_ h: Session) -> Int {
        let w = warmIds(h.day)
        return h.entries.keys.filter { !w.contains($0) }.count
    }

    /// `historyItems()`: newest first, lifts before cardio on the same day.
    /// (Two cardio entries on one date keep their stored order; the web's comparator is
    /// inconsistent there, so its order depends on the JS engine.)
    public func historyItems() -> [HistoryItem] {
        var out: [HistoryItem] = []
        for (i, h) in db.history.enumerated() { out.append(HistoryItem(date: h.date, kind: "lift", index: i)) }
        for (i, c) in db.cardio.enumerated() where c.type != "jumps" { out.append(HistoryItem(date: c.date, kind: c.type, index: i)) }
        return out.stableSorted { a, b in
            if a.date != b.date { return a.date > b.date }
            return a.kind == "lift" && b.kind != "lift"
        }
    }

    /// `topSets(id, weeks)`
    public func topSets(_ id: String, weeks: Int) -> [TopSet] {
        let from = Dates.addDays(Dates.mondayOf(today), -7 * (weeks - 1))
        return db.history.filter { $0.date >= from && $0.entries[id] != nil }.map { TopSet(d: $0.date, v: $0.entries[id]!.w) }
    }

    /// The Progress screen's lifts: key, non-bodyweight lifts of the whole rotation.
    public func progressLifts() -> [Ex] { days.flatMap { requiredItems($0) }.filter { $0.isKey && !$0.isBodyweight } }

    public func defaultProgressLift() -> String? {
        let keys = progressLifts()
        return (keys.first { $0.id.contains("rdl") } ?? keys.first)?.id
    }

    /// The points of the top-set chart (`progressView`).
    public func progressPoints(lift: String, weeks: Int) -> [ProgressPoint] {
        var byWeek: [String: Double] = [:]
        for p in topSets(lift, weeks: weeks) {
            let m = Dates.mondayOf(p.d)
            byWeek[m] = max(byWeek[m] ?? 0, p.v)
        }
        let base = Dates.addDays(Dates.mondayOf(today), -7 * (weeks - 1))
        return byWeek.keys.sorted().map { m in
            weeks <= 8
                ? ProgressPoint(l: "W" + jsNum(jsRound(Double(Dates.dayDiff(base, m)) / 7) + 1), y: byWeek[m]!)
                : ProgressPoint(l: Dates.fmtD(m, .init(month: .short)), y: byWeek[m]!)
        }
    }

    /// Eight weeks ending with this one: rings, cardio sessions and office-day steps.
    public func progressWeeks() -> (stats: [WeekStats], cardio: [Int], steps: [Int]) {
        let mon = Dates.mondayOf(today)
        let w8 = (0..<8).map { Dates.addDays(mon, -7 * (7 - $0)) }
        let stats = w8.map { weekStats($0) }
        let cardio = w8.map { m -> Int in let ds = Dates.weekDates(m); return db.cardio.filter { ds.contains($0.date) && $0.type != "jumps" }.count }
        let steps = w8.map { m -> Int in
            let ds = Dates.weekDates(m)
            let s = db.cardio.filter { ds.contains($0.date) && $0.type == "office" && ($0.steps ?? 0) != 0 }
            return s.isEmpty ? 0 : Int(jsRound(s.reduce(0) { $0 + $1.steps! } / Double(s.count)))
        }
        return (stats, cardio, steps)
    }

    // MARK: logging

    /// `logCardio(type, extra, date)`: one entry per type per day, kept sorted by date.
    public mutating func logCardio(_ type: String, _ extra: CardioEntry = CardioEntry(date: "", type: ""), date: String? = nil) {
        let d = date ?? today
        db.cardio.removeAll { $0.date == d && $0.type == type }
        var e = extra
        e.date = d; e.type = type
        db.cardio.append(e)
        db.cardio = db.cardio.stableSorted { $0.date < $1.date }
    }
}

public struct WeekStripItem: Codable, Equatable {
    public var w: Int
    public var kind: String       // "normal" or "skip"
    public var label: String
    public var color: String      // hex
    public var done: Bool
    public var today: Bool
}

extension Engine {
    /// The seven day buttons of the week strip on Today (`todayView`).
    public func weekStrip() -> [WeekStripItem] {
        let t = today, mon = Dates.mondayOf(t), wp = weekPlan(), slots = liftSlots(mon), ds = Dates.weekDates(mon)
        let KC = ["m": "#9C8CFF", "h": "#FF6B4A", "b": "#4ADE80"]
        return Engine.wdOrder.enumerated().map { (i, w) in
            let s = wp[w] ?? "rest", d = ds[i], sk = skipOn(d)
            let gymDone = s == "lift" ? liftedOn(d) != nil : s == "office" ? cardioOn(d, "office") != nil
                : (catalog.ctype[s].map { cardioOn(d, $0) != nil } ?? false)
            if let sk = sk, !gymDone {
                let ring = catalog.home[sk.key]?.ring ?? "h"
                return WeekStripItem(w: w, kind: "skip", label: sk.why == "sick" ? "Rest" : "Home",
                                     color: sk.why == "sick" ? "#6E7385" : KC[ring]!, done: (sk.done ?? 0) != 0, today: d == t)
            }
            let col = s == "lift" ? KC["m"]! : heartSlots.contains(s) ? KC["h"]! : "#6E7385"
            let lab: String
            if s == "lift" {
                if let day = slots[w]?.day, let name = plan[day]?.name {
                    lab = name.replacingOccurrences(of: "Upper", with: "Up", options: [], range: name.range(of: "Upper"))
                        .replacingOccurrences(of: "Legs", with: "Leg", options: [], range: nil)
                } else { lab = "—" }
            } else { lab = ["office": "Office", "z2": "Z2", "vo2": "4×4", "walk": "Walk", "rest": "Rest"][s] ?? "" }
            return WeekStripItem(w: w, kind: "normal", label: lab, color: col, done: gymDone, today: d == t)
        }
    }

    /// `greet()`: by the local hour.
    public func greet() -> String {
        let off = tz.secondsFromGMT(for: Date(timeIntervalSince1970: nowMs / 1000))
        let localSec = Int((nowMs / 1000).rounded(.down)) + off
        let h = ((localSec % 86_400) + 86_400) % 86_400 / 3600
        return h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening"
    }
}

// MARK: History rows and chart scales (app.js histRow, lineSVG)

public struct HistoryRowText: Codable, Equatable {
    public var name: String
    public var meta: String
    public var right: String
    public var icon: String       // "lift", "home", "heart" or "walk"
    public var jumps: Bool        // the lift row's "· jumps" is mint
}

public struct ChartScale: Codable, Equatable {
    public var y0: Double
    public var y1: Double
    public var ticks: [Double]
}

extension Engine {
    /// The text of one History row (`histRow`).
    public func historyRow(_ it: HistoryItem) -> HistoryRowText {
        if it.kind == "lift" {
            let h = db.history[it.index]
            let nm = plan[h.day]?.name ?? "Workout"
            let j = cardioOn(h.date, "jumps") != nil
            let meta = "\(exCount(h)) exercises" + (j ? " · jumps" : "") + ((h.lowEnergy ?? false) ? " · lighter" : "")
            let right = (h.min ?? 0) != 0 ? "\(jsMinutes(h.min!)) min" : "\(Fmt.nf(h.vol ?? 0)) lb"
            return HistoryRowText(name: nm, meta: meta, right: right, icon: "lift", jumps: j)
        }
        let c = db.cardio[it.index]
        var nm: String
        if let a = c.act, let def = catalog.cardioActs[a] {
            nm = def.n + (c.type == "4x4" ? " · 4×4" : c.type == "z2" ? " · Zone 2" : "")
        } else {
            let names = ["office": "Office day", "4x4": "4×4 intervals", "z2": "Zone 2 walk", "walk": "Walk", "cardio": "Cardio",
                         "home": c.focus == "legs" ? "Home legs + bone" : "Home upper"]
            nm = names[c.type] ?? c.type
        }
        let right = c.type == "office" ? "\(Fmt.nf(c.steps ?? 0)) steps"
            : c.type == "4x4" ? "\((c.intervals ?? 0) != 0 ? jsMinutes(c.intervals!) : "4") × 4 min"
            : "\(jsMinutes(c.min ?? 0)) min"
        let sub: String
        if let hr = c.avgHR, hr != 0 { sub = "Avg \(jsMinutes(hr)) bpm" + ((c.elev ?? 0) != 0 ? " · +\(jsMinutes(c.elev!)) m" : "") }
        else if (c.home ?? 0) != 0 { sub = "At home" }
        else if c.type == "home" { sub = "At home · bodyweight" }
        else if c.type == "office" { sub = "Walk to and from work" }
        else if c.type == "4x4" { sub = (c.min ?? 0) != 0 ? "\(jsMinutes(c.min!)) min total" : "Intervals" }
        else { sub = "Easy pace" }
        let icon = c.type == "home" ? "home" : c.type == "4x4" ? "heart" : "walk"
        return HistoryRowText(name: nm, meta: sub, right: right, icon: icon, jumps: false)
    }

    /// Y range and ticks of a line chart (`lineSVG`).
    public static func chartScale(_ ys: [Double]) -> ChartScale {
        let lo = ys.min() ?? 0, hi = ys.max() ?? 0, pad = max(5, (hi - lo) * 0.2)
        let y0 = ((lo - pad) / 5).rounded(.down) * 5, y1 = ((hi + pad) / 5).rounded(.up) * 5
        return ChartScale(y0: y0, y1: y1, ticks: [y0, jsRound((y0 + y1) / 2), y1])
    }
}
