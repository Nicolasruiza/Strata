import Foundation

public struct HRTargets: Codable, Equatable {
    public var max: Int
    public var z2: [Int]
    public var hard: [Int]
}

public struct Phase: Codable, Equatable {
    public var k: String          // "easy" or "hard"
    public var label: String
    public var sec: Int
}

public struct PhaseAt: Codable, Equatable {
    public var i: Int
    public var p: Phase
    public var into: Double
    public var left: Double
    public var over: Int?
}

public struct CardioStats: Codable, Equatable {
    /// Seconds per zone; index 0 is unused, 1…5 are Z1…Z5.
    public var z: [Double]
    public var avg: Int?
    public var max: Double?
    public var hr: Double?
    public var elev: Int?
    public var zonesOK: Bool
}

public struct CardioPlan: Codable, Equatable {
    public var slot: String
    public var kind: String
    public var mode: String
    public var n: Int
    public var act: String
    public var title: String
    public var sub: String
}

/// A heart-rate / altitude reading, the shape `Sensors.read(t)` returns.
public struct SensorReading: Codable, Equatable {
    public var hr: Double?
    public var alt: Double?
    public init(hr: Double?, alt: Double?) { self.hr = hr; self.alt = alt }
}

/// What `Health.saveWorkout(entry)` receives.
public struct HealthPayload: Codable, Equatable {
    public var min: Double
    public var act: String
    public var avgHR: Double?
    public var maxHR: Double?
    public var zones: [Double]?
    public var elev: Double?
    public var intervals: Double?
    public var type: String
    public var start: Double
    public var end: Double
    public var samples: [Sample]
}

extension Engine {
    // MARK: heart-rate targets (core.js rcHR … rcDefaultIntervals)

    /// `rcHR()`: nil without a plausible age, so no age means no zones.
    public func rcHR() -> HRTargets? {
        guard let a = db.age, a != 0, a >= Config.Heart.minAge, a <= Config.Heart.maxAge else { return nil }
        let mx = jsRound(Config.Heart.maxIntercept - Config.Heart.maxPerYear * a)
        func r(_ f: Double) -> Int { Int(jsRound(mx * f)) }
        return HRTargets(max: Int(mx), z2: [r(Config.Heart.z2[0]), r(Config.Heart.z2[1])],
                         hard: [r(Config.Heart.hard[0]), r(Config.Heart.hard[1])])
    }
    public func hrMax() -> Int? { rcHR()?.max }

    /// `rcPhases(n)`
    public static func rcPhases(_ n: Int) -> [Phase] {
        let I = Config.Intervals.self
        var ph = [Phase(k: "easy", label: "Warm-up · easy", sec: I.warmupSec)]
        if n >= 1 {
            for i in 1...n {
                ph.append(Phase(k: "hard", label: "Interval \(i) of \(n) · hard", sec: I.hardSec))
                if i < n { ph.append(Phase(k: "easy", label: "Recover \(i) of \(n - 1) · easy", sec: I.recoverSec)) }
            }
        }
        ph.append(Phase(k: "easy", label: "Cool-down", sec: I.cooldownSec))
        return ph
    }
    public func rcPhases(_ n: Int) -> [Phase] { Engine.rcPhases(n) }

    /// `rcMinutes(n)`
    public func rcMinutes(_ n: Int) -> Int {
        let I = Config.Intervals.self
        return (I.warmupSec + n * I.hardSec + (n - 1) * I.recoverSec + I.cooldownSec) / 60
    }
    public func rc4x4Count() -> Int { db.cardio.filter { $0.type == "4x4" }.count }
    public func rcDefaultIntervals() -> Int {
        rc4x4Count() < Config.Intervals.rampSessions ? Config.Intervals.rampCount : Config.Intervals.fullCount
    }

    // MARK: zones (workout.js zoneOf, zoneRange)

    public func zoneOf(_ hr: Double, _ M: Double) -> Int {
        let f = hr / M, t = Config.workout.zoneTops
        return f < t[0] ? 1 : f < t[1] ? 2 : f < t[2] ? 3 : f < t[3] ? 4 : 5
    }
    public func zoneRange(_ z: Int, _ M: Double) -> [Int] {
        let t = [0] + Config.workout.zoneTops + [1.1]
        return [Int(jsRound(M * t[z - 1])), Int(jsRound(M * t[z]))]
    }

    // MARK: cardio stats from stored readings

    /// `cardioStats(L, el)`: time-weighted average, max, time per zone, elevation gain with a
    /// noise filter. Gaps longer than `maxSampleGapSec` are not credited.
    public func cardioStats(samples S: [Sample], elapsed el: Double) -> CardioStats {
        let M = hrMax().map(Double.init), cfg = Config.workout
        var z = [Double](repeating: 0, count: 6)
        var wsum = 0.0, wt = 0.0, mx = 0.0, gain = 0.0
        var ref: Double?
        for (i, s) in S.enumerated() {
            let nx = i + 1 < S.count ? S[i + 1] : nil
            let dt = max(0, min((nx?.t ?? el) - s.t, cfg.maxSampleGapSec))
            if let hr = s.hr {
                if let M = M, M != 0 { z[zoneOf(hr, M)] += dt }
                wsum += hr * dt; wt += dt; mx = max(mx, hr)
            }
            if let alt = s.alt {
                if let r = ref {
                    let d = alt - r
                    if abs(d) >= cfg.elevNoiseM { if d > 0 { gain += d }; ref = alt }
                } else { ref = alt }
            }
        }
        let cur = S.last { $0.hr != nil }
        return CardioStats(
            z: z,
            avg: wt != 0 ? Int(jsRound(wsum / wt)) : nil,
            max: mx != 0 ? mx : nil,
            hr: (cur != nil && el - cur!.t <= cfg.maxSampleGapSec) ? cur!.hr : nil,
            elev: S.contains { $0.alt != nil } ? Int(jsRound(gain)) : nil,
            zonesOK: (M ?? 0) != 0 && wt != 0)
    }

    /// `liveEl(L)`: timestamp based, so it keeps counting in the background.
    public func liveElapsed(_ L: LiveCardio) -> Double { max(0, ((nowMs - L.started) / 1000).rounded(.down)) }

    /// `phaseAt(t, L)`
    public func phaseAt(_ t: Double, n: Int?) -> PhaseAt {
        let ph = rcPhases((n ?? 0) != 0 ? n! : Config.Intervals.displayFallbackCount)
        var s = 0.0
        for i in ph.indices {
            if t < s + Double(ph[i].sec) { return PhaseAt(i: i, p: ph[i], into: t - s, left: s + Double(ph[i].sec) - t, over: nil) }
            s += Double(ph[i].sec)
        }
        return PhaseAt(i: ph.count - 1, p: ph[ph.count - 1], into: 0, left: 0, over: 1)
    }

    /// `hardDone(L, el)`: a hard interval counts once 75% of it is done.
    public func hardDone(n: Int?, elapsed el: Double) -> Int {
        var s = 0.0, count = 0
        for p in rcPhases(n ?? 0) {
            if p.k == "hard" && el - s >= Double(p.sec) * Config.workout.intervalCreditFrac { count += 1 }
            s += Double(p.sec)
        }
        return count
    }

    // MARK: what today asks for (workout.js lastActFor, cardioPlan)

    public static func modeLbl(_ m: String) -> String { m == "4x4" ? "4×4" : m == "z2" ? "Zone 2" : "" }

    /// `lastActFor(match)` for `x.type === type`.
    public func lastActFor(type: String) -> String? {
        db.cardio.last { $0.act != nil && catalog.cardioActs[$0.act!] != nil && $0.type == type }?.act
    }

    public func cardioPlan() -> CardioPlan {
        let slot = weekPlan()[Dates.weekday(today)] ?? "rest", n = rcDefaultIntervals()
        let kind = slot == "vo2" ? "4x4" : slot == "z2" ? "z2" : slot == "walk" ? "walk" : slot == "office" ? "office" : "other"
        let mode = kind == "4x4" ? "4x4" : kind == "z2" ? "z2" : "free"
        let type = kind == "4x4" ? "4x4" : kind == "z2" ? "z2" : kind == "walk" ? "walk" : "cardio"
        let act = lastActFor(type: type) ?? Config.workout.fallbackAct[kind]!
        let sub = kind == "4x4" ? "\(n) hard intervals with recovery · ~\(rcMinutes(n)) min" : (Config.workout.guide[kind] ?? "")
        let title = catalog.cardioActs[act]!.n + (mode != "free" ? " · " + Engine.modeLbl(mode) : "")
        return CardioPlan(slot: slot, kind: kind, mode: mode, n: n, act: act, title: title, sub: sub)
    }

    /// The "Recent" rows of the picker: the last two distinct activities.
    public func recentCardio() -> [CardioEntry] {
        var recent: [CardioEntry] = []
        for c in db.cardio.reversed() {
            if let a = c.act, catalog.cardioActs[a] != nil, !recent.contains(where: { $0.act == a }), recent.count < 2 { recent.append(c) }
        }
        return recent
    }

    /// `ago(d)` in the picker.
    public func agoLabel(_ d: String) -> String {
        let n = Dates.dayDiff(d, today)
        return n == 0 ? "Today" : n == 1 ? "Yesterday" : Dates.fmtD(d, .init(weekday: .short))
    }

    // MARK: running a cardio session

    /// The inside of `startCardio()` once the 3-2-1 countdown ends.
    public mutating func startCardio(act: String?, reading: SensorReading) {
        let P = cardioPlan()
        db.live = LiveCardio(act: act ?? P.act, mode: P.mode, n: P.n, slot: P.slot, started: nowMs, date: today, samples: [])
        takeSample(reading: reading)
    }

    /// `takeSample()`: store a reading every `sampleEverySec`. Returns whether one was stored.
    @discardableResult
    public mutating func takeSample(reading: SensorReading) -> Bool {
        guard var L = db.live else { return false }
        let el = liveElapsed(L)
        var S = L.samples ?? []
        if let last = S.last, el - last.t < Config.workout.sampleEverySec { return false }
        S.append(Sample(t: el, hr: reading.hr, alt: reading.alt))
        L.samples = S
        db.live = L
        return true
    }

    /// The first half of `completeCardio()`: log the block, return what Health should save.
    public mutating func endCardio(reading: SensorReading) -> HealthPayload? {
        takeSample(reading: reading)
        guard let L = db.live else { return nil }
        let el = liveElapsed(L), s = cardioStats(samples: L.samples ?? [], elapsed: el)
        let min = max(1, jsRound(el / 60))
        let type = L.mode == "4x4" ? "4x4" : L.mode == "z2" ? "z2" : L.slot == "walk" ? "walk" : "cardio"
        var extra = CardioEntry(date: L.date, type: type, min: min, act: L.act)
        if let avg = s.avg { extra.avgHR = Double(avg); extra.maxHR = s.max }
        if s.zonesOK { extra.zones = Array(s.z.dropFirst()) }
        if let e = s.elev { extra.elev = Double(e) }
        if type == "4x4" { extra.intervals = Double(hardDone(n: L.n, elapsed: el)) }
        logCardio(type, extra, date: L.date)
        wLast = WLast(min: min, act: L.act, avgHR: extra.avgHR, maxHR: extra.maxHR, zones: extra.zones, elev: extra.elev,
                      intervals: extra.intervals, type: type, date: L.date, health: false)
        return HealthPayload(min: min, act: L.act, avgHR: extra.avgHR, maxHR: extra.maxHR, zones: extra.zones, elev: extra.elev,
                             intervals: extra.intervals, type: type, start: L.started, end: nowMs, samples: L.samples ?? [])
    }

    /// The second half: record what `Health.saveWorkout()` really returned, then close the session.
    public mutating func recordHealthResult(saved: Bool) {
        wLast?.health = saved
        db.live = nil
    }

    /// `cdiscard`: nothing is saved.
    public mutating func discardCardio() { db.live = nil }
}

/// `vo2Done`: the block logged from the 4×4 info screen.
public struct Vo2Done: Codable, Equatable {
    public var intervals: Int
    public var min: Int
    public var date: String
}

extension Engine {
    /// "Already did it? Log without the timer" on the 4×4 screen. `n` is the chosen count.
    @discardableResult
    public mutating func logVo2(n: Int?) -> Vo2Done {
        let n = n ?? rcDefaultIntervals()
        logCardio("4x4", CardioEntry(date: "", type: "", min: Double(rcMinutes(n)), intervals: Double(n)))
        let v = Vo2Done(intervals: n, min: rcMinutes(n), date: today)
        vo2Done = v
        return v
    }

    /// The ramp-up line on the 4×4 info screen.
    public func vo2Ramp() -> String {
        let c = rc4x4Count()
        return c < Config.Intervals.rampSessions
            ? "Ramp-up session \(c + 1) of \(Config.Intervals.rampSessions): \(Config.Intervals.rampCount) intervals at the low end of the range."
            : "Full 4×4. Add speed or incline when the last interval feels easier than the first."
    }

    /// Texts on the 4×4 complete screen (`vo2DoneView`), for the block `v` (or the default one).
    public func vo2DoneView(_ v: Vo2Done?) -> (v: Vo2Done, st: WeekStats, sub: String, ringsLine: String, note: String) {
        let d = v ?? Vo2Done(intervals: Config.Intervals.fullCount, min: rcMinutes(Config.Intervals.fullCount), date: today)
        let st = weekStats(Dates.mondayOf(d.date))
        let sub = st.all ? "All 3 rings closed this week." : st.closed[1] ? "Heart ring closed for the week." : "Heart work logged."
        let line = st.all ? "Muscle, heart and bone: the full week is in." : ringsLine(st)
        let note = rc4x4Count() < Config.Intervals.rampSessions
            ? "Ramp-up phase: keep it at 3 intervals until you have 3 sessions in."
            : "Next time, add a little speed or incline if the last interval felt easier than the first."
        return (d, st, sub, line, note)
    }

    /// "Heart ring closed for the week." sub-line of the cardio complete screen.
    public func cardioDoneSub(_ st: WeekStats) -> String { st.closed[1] ? "Heart ring closed for the week." : "Heart work logged." }
}
