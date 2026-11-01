import Foundation

/// The header a web export adds in front of the data (`planKey`, `profileName`, …).
public struct ExportHeader: Codable, Equatable {
    public var app: String?
    public var profile: String?
    public var profileName: String?
    public var planKey: String?
}

extension Engine {
    // MARK: can't train today (app.js SKIP_WHY, HOME, homeKey, data-why, homeDone, undoSkip)

    public func homeKey(slot: String, date: String) -> String {
        if slot == "lift" {
            let d = (skipOn(date)?.day).flatMap { $0 != 0 ? $0 : nil } ?? nextDay()
            return isLegs(d) ? "legs" : "upper"
        }
        return slot == "vo2" ? "vo2" : "walk"
    }

    /// Pick a reason. Returns the toast.
    public mutating func skipToday(why: String) -> String {
        let t = today, slot = weekPlan()[Dates.weekday(t)] ?? "rest"
        var s = db.skips ?? [:]
        s[t] = Skip(why: why, slot: slot, key: homeKey(slot: slot, date: t), day: slot == "lift" ? nextDay() : nil, done: nil)
        db.skips = s
        return why == "sick" ? "Rest day. The rotation waits." : "Here's a home version"
    }

    public mutating func undoSkip(_ date: String) -> String {
        if db.skips != nil { db.skips![date] = nil }
        return "Back on the plan"
    }

    /// "Mark done" on a home session.
    public mutating func homeDone(_ date: String) -> String? {
        guard let sk = skipOn(date), let H = catalog.home[sk.key] else { return nil }
        let min = Double(H.min)
        switch sk.key {
        case "legs":
            logCardio("home", CardioEntry(date: "", type: "", min: min, focus: "legs"), date: date)
            logCardio("jumps", CardioEntry(date: "", type: "", landings: Double(Config.landingsHomeLegs), home: 1), date: date)
        case "upper":
            logCardio("home", CardioEntry(date: "", type: "", min: min, focus: "upper"), date: date)
        case "vo2":
            logCardio("4x4", CardioEntry(date: "", type: "", min: min, intervals: Double(Config.Intervals.fullCount), home: 1), date: date)
        default:
            logCardio(sk.slot == "office" ? "walk" : (catalog.ctype[sk.slot] ?? "walk"), CardioEntry(date: "", type: "", min: min, home: 1), date: date)
        }
        db.skips![date]!.done = 1
        return "Home session logged · momentum kept"
    }

    // MARK: logging from Today

    /// "Log steps": digits only, as typed. Returns the toast.
    public mutating func logSteps(date: String, input: String) -> String {
        let v = Double(input.filter(\.isNumber)) ?? 0
        if v == 0 { return "Type your steps first" }
        logCardio("office", CardioEntry(date: "", type: "", steps: v), date: date)
        return "\(Fmt.nf(v)) steps logged"
    }
    public mutating func logMinutes(slot: String, min: Double) -> String? {
        if min == 0 { return nil }
        logCardio(catalog.ctype[slot] ?? slot, CardioEntry(date: "", type: "", min: min))
        return "Logged · \(jsNum(min)) min"
    }
    public mutating func logWalk(type: String, min: Double) -> String? {
        if min == 0 { return nil }
        logCardio(type, CardioEntry(date: "", type: "", min: min))
        return "Walk logged · \(jsNum(min)) min"
    }
    /// The cardio edit sheet's Save.
    public mutating func editCardio(date: String, type: String, value: Double) {
        guard let i = db.cardio.firstIndex(where: { $0.date == date && $0.type == type }) else { return }
        if type == "office" { db.cardio[i].steps = value }
        else if type == "4x4" { db.cardio[i].intervals = value }
        else { db.cardio[i].min = value }
    }
    public mutating func deleteCardio(date: String, type: String) { db.cardio.removeAll { $0.date == date && $0.type == type } }

    // MARK: settings

    public mutating func adjustAge(_ dir: Int) {
        db.age = min(Config.Heart.maxAge, max(Config.Heart.minAge, (db.age ?? 0) != 0 ? db.age! + Double(dir) : Config.defaultAge + Double(dir)))
    }
    public mutating func toggleOfficeDay(_ d: Int) {
        var off = officeDays()
        if let i = off.firstIndex(of: d) { off.remove(at: i) } else { off.append(d) }
        db.officeDays = off.sorted()
    }
    public mutating func addWaist(cm: Double) -> String {
        if !(cm > Config.waistRangeCm.min && cm < Config.waistRangeCm.max) { return "Type your waist in cm" }
        var w = (db.waist ?? []).filter { $0.date != today }
        w.append(Waist(date: today, cm: cm))
        db.waist = w.stableSorted { $0.date < $1.date }
        return "Waist saved"
    }
    public func genderPrompt(_ g: String) -> String { "Switch to the \(g) plan template? Your history and weights stay." }
    public mutating func setGender(_ g: String) -> String? {
        if g == profile.gender { return nil }
        profile.gender = g
        profile.plan = g == "female" ? "sa" : "nr"
        profile.bw = g == "female" ? Config.Profiles.femaleBodyweight : Config.Profiles.maleBodyweight
        profile.exp = g == "female" ? Config.Profiles.femaleExp : Config.Profiles.maleExp
        setActivePlan()
        return "Plan template updated"
    }
    public mutating func rename(_ name: String) -> String? {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if n.isEmpty { return nil }
        profile.name = n
        profile.initials = String(n.prefix(2)).uppercased()
        return "Name saved"
    }
    public static func newProfile(name: String, gender: String) -> Profile {
        let f = gender == "female"
        return Profile(id: "me", name: name, initials: name.isEmpty ? "?" : String(name.prefix(2)).uppercased(), gender: gender,
                       plan: f ? "sa" : "nr", bw: f ? Config.Profiles.femaleBodyweight : Config.Profiles.maleBodyweight,
                       exp: f ? Config.Profiles.femaleExp : Config.Profiles.maleExp)
    }
    public var resetPrompt: String { "Erase all of \(profile.name)'s history and weights? This can't be undone." }
    public mutating func reset() -> String { db = AppData.fresh(); setActivePlan(); return "Reset" }

    /// "Get started" on the first-launch screen.
    public mutating func completeOnboarding(name: String, age: Double?, officeDays: [Int]) {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.name = n
        profile.initials = String(n.prefix(2)).uppercased()
        if let a = age, a != 0 { db.age = a }
        db.officeDays = officeDays
    }

    // MARK: history detail

    public mutating func toggleSessionJumps(_ idx: Int) {
        guard idx >= 0, idx < db.history.count else { return }
        let d = db.history[idx].date
        if cardioOn(d, "jumps") != nil { db.cardio.removeAll { $0.date == d && $0.type == "jumps" } }
        else { logCardio("jumps", CardioEntry(date: "", type: "", landings: Double(Config.landingsPerJumpDay)), date: d) }
    }
    public var deleteSessionPrompt: String { "Delete this session permanently?" }
    public mutating func deleteSession(_ idx: Int) -> String? {
        guard idx >= 0, idx < db.history.count else { return nil }
        db.history.remove(at: idx)
        return "Session deleted"
    }
    private mutating func recalcVolume(_ idx: Int) {
        let s = db.history[idx]
        var v = 0.0
        for id in s.entries.keys { v += volOf(id, s.entries[id]!.w, s.entries[id]!.reps) }
        db.history[idx].vol = jsRound(v)
    }
    public mutating func editSessionWeight(_ idx: Int, id: String, w: Double) {
        guard idx >= 0, idx < db.history.count, db.history[idx].entries[id] != nil else { return }
        db.history[idx].entries[id]!.w = w
        recalcVolume(idx)
    }
    public mutating func editSessionRep(_ idx: Int, id: String, set k: Int, value: Double?) {
        guard idx >= 0, idx < db.history.count, db.history[idx].entries[id] != nil, k >= 0 else { return }
        while db.history[idx].entries[id]!.reps.count <= k { db.history[idx].entries[id]!.reps.append(nil) }
        db.history[idx].entries[id]!.reps[k] = value
        recalcVolume(idx)
    }

    // MARK: export and import (same JSON as the web)

    public func exportFileName() -> String {
        let base = profile.name.isEmpty ? "me" : profile.name.lowercased()
        let slug = base.replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
        return "strata-\(slug)-\(today).json"
    }

    public func exportData() throws -> Data {
        let body = String(decoding: try db.jsonData(), as: UTF8.self)
        func js(_ s: String) -> String { String(decoding: (try? JSONEncoder().encode(s)) ?? Data(), as: UTF8.self) }
        let head = "{\"app\":\"strata\",\"profile\":\(js(profile.id)),\"profileName\":\(js(profile.name)),\"planKey\":\(js(profile.plan))"
        let rest = body.dropFirst()                       // drop the leading "{"
        return Data((head + (rest == "}" ? "}" : "," + rest)).utf8)
    }

    /// The confirm text before an import replaces the current data, or nil to go straight ahead.
    public func importPrompt(_ h: ExportHeader, quiet: Bool) -> String? {
        let plan = h.planKey ?? ((h.profile == "nr" || h.profile == "sa") ? h.profile : nil)
        if quiet { return nil }
        if let plan = plan, plan != profile.plan {
            return "This file is from \(h.profileName ?? plan). Import it into \(profile.name) anyway? \(profile.name)'s current data will be replaced."
        }
        if plan == nil { return "Replace \(profile.name)'s data with this file?" }
        return nil
    }

    /// `applyImport(p)`
    public mutating func applyImport(_ p: AppData) {
        db.next = p.next
        db.history = p.history.stableSorted { $0.date < $1.date }
        db.active = nil
        db.holds = p.holds
        db.cycleStarts = p.cycleStarts
        db.focus = p.focus
        db.injuries = p.injuries
        db.cycleAnchor = p.cycleAnchor
        db.cardio = p.cardio
        if let a = p.age, a != 0 { db.age = a }
        if p.rcOffice != nil { db.rcOffice = p.rcOffice }
        if p.officeDays != nil { db.officeDays = p.officeDays }
        if p.waist != nil { db.waist = p.waist }
        setActivePlan()
    }
}
