import XCTest
@testable import StrataCore

/// Replays every case in Fixtures/logic.<tz>.json: the same inputs go into the Swift
/// twin and the output (plus the data it leaves behind, toasts and confirm prompts) must
/// equal what the web's own code produced.
final class LogicFixtureTests: XCTestCase {
    func testTorontoFixtures() throws { try replay("logic.America_Toronto") }
    func testUTCFixtures() throws { try replay("logic.UTC") }

    // MARK: harness

    struct Outcome {
        var ret: Any?
        var toasts: [String] = []
        var confirms: [String] = []
    }

    func replay(_ name: String) throws {
        let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")!
        let raw = try Data(contentsOf: url)
        let file = try JSONSerialization.jsonObject(with: raw) as! [String: Any]
        let ordered = try OJParser.parse(raw)
        let tz = TimeZone(identifier: file["tz"] as! String)!
        let scenarios = file["scenarios"] as! [String: [String: Any]]
        let cases = file["cases"] as! [[String: Any]]
        XCTAssertGreaterThan(cases.count, 1000)

        // scenarios keep their key order: re-serialise the ordered subtree
        var dbData: [String: Data] = [:]
        for (k, _) in scenarios {
            dbData[k] = Data(OJParser.write(ordered["scenarios"]![k]!["db"]!).utf8)
        }
        var failures: [String] = []
        var byFn: [String: Int] = [:]
        for (ci, c) in cases.enumerated() {
            let id = c["id"] as! String
            let sc = scenarios[c["scenario"] as! String]!
            do {
                var e = Engine(profile: try JSONCompare.decode(Profile.self, from: sc["profile"]!),
                               db: try AppData.load(from: dbData[c["scenario"] as! String]!),
                               nowMs: Self.parseInstant(c["now"] as! String), tz: tz)
                let pre = (c["pre"] as? [String: Any]) ?? [:]
                if let r = pre["rest"] { e.rest = try JSONCompare.decode(RestState.self, from: r) }
                if let r = pre["celebration"] { e.celebration = try JSONCompare.decode(Celebration.self, from: r) }
                if let w = pre["wLast"] { e.wLast = try JSONCompare.decode(WLast.self, from: w) }
                e.woReps = (pre["woReps"] as? NSNumber)?.doubleValue
                e.preLow = (pre["preLow"] as? Bool) ?? false

                let confirm = (c["confirm"] as? Bool) ?? true
                let out: Outcome
                if let click = c["click"] as? [String: Any] {
                    out = try runClick(&e, click, pre: pre, confirm: confirm)
                } else {
                    out = try runFn(&e, c["fn"] as! String, (c["args"] as? [Any]) ?? [], pre: pre, confirm: confirm)
                }
                byFn[c["fn"] as! String, default: 0] += 1

                if c["click"] == nil, let d = JSONCompare.diff(c["ret"], out.ret) { failures.append("\(id): ret \(d)") }
                if let after = c["after"] as? [String: Any] {
                    var mine: [String: Any] = [
                        "db": JSONCompare.object(e.db) ?? NSNull(), "rest": JSONCompare.object(e.rest) ?? NSNull(),
                        "celebration": JSONCompare.object(e.celebration) ?? NSNull(), "woReps": e.woReps ?? NSNull(),
                        "preLow": e.preLow, "wLast": JSONCompare.object(e.wLast) ?? NSNull(), "profile": JSONCompare.object(e.profile) ?? NSNull()]
                    if let p = out.ret, c["click"] != nil { mine["payload"] = p }
                    var theirs = after
                    theirs["view"] = nil
                    if c["click"] == nil { theirs["payload"] = nil }
                    if let d = JSONCompare.diff(theirs, mine) { failures.append("\(id): state \(d)") }
                    if (c["toasts"] as? [String] ?? []) != out.toasts { failures.append("\(id): toasts \(out.toasts) != \(c["toasts"] ?? [])") }
                    if (c["confirms"] as? [String] ?? []) != out.confirms { failures.append("\(id): confirms \(out.confirms) != \(c["confirms"] ?? [])") }
                    // entries keep the order they were logged in
                    if let h = ordered["cases"]?.items[ci]["after"]?["db"]?["history"]?.items.last?["entries"], let mineLast = e.db.history.last {
                        if h.keys != mineLast.entries.keys && (c["fn"] as? String) == "endSession" { failures.append("\(id): entries order \(mineLast.entries.keys) != \(h.keys)") }
                    }
                }
            } catch {
                failures.append("\(id): threw \(error)")
            }
        }
        print("\(name): \(cases.count) cases, \(byFn.count) functions, \(failures.count) failures")
        XCTAssertTrue(failures.isEmpty, "\(failures.count) of \(cases.count) fixtures differ:\n" + failures.prefix(40).joined(separator: "\n"))
    }

    static func parseInstant(_ s: String) -> Double {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        if let d = f.date(from: s) { return d.timeIntervalSince1970 * 1000 }
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: s)!.timeIntervalSince1970 * 1000
    }

    // MARK: argument helpers

    func str(_ a: [Any], _ i: Int) -> String { a[i] as? String ?? "" }
    func dbl(_ a: [Any], _ i: Int) -> Double { (a[i] as? NSNumber)?.doubleValue ?? 0 }
    func int(_ a: [Any], _ i: Int) -> Int { Int(dbl(a, i)) }
    func strs(_ a: [Any], _ i: Int) -> [String] { a[i] as? [String] ?? [] }
    func reps(_ a: [Any], _ i: Int) -> [Double?] { (a[i] as! [Any]).map { ($0 as? NSNumber)?.doubleValue } }
    func cardioExtra(_ any: Any?) throws -> CardioEntry {
        var d = (any as? [String: Any]) ?? [:]
        d["date"] = ""; d["type"] = ""
        return try JSONCompare.decode(CardioEntry.self, from: d)
    }
    struct LArg: Decodable { var samples: [Sample]?; var n: Int? }
    func obj<T: Encodable>(_ v: T?) -> Any? { v.flatMap { JSONCompare.object($0) } }
    func reading(_ pre: [String: Any]) -> SensorReading {
        let r = pre["reading"] as? [String: Any]
        return SensorReading(hr: (r?["hr"] as? NSNumber)?.doubleValue, alt: (r?["alt"] as? NSNumber)?.doubleValue)
    }

    // MARK: functions

    func runFn(_ e: inout Engine, _ fn: String, _ a: [Any], pre: [String: Any], confirm: Bool) throws -> Outcome {
        var o = Outcome()
        func toast(_ t: String?) { if let t = t, !t.isEmpty { o.toasts.append(t) } }
        switch fn {
        case "activePlan": o.ret = obj(e.ap)
        case "requiredItems": o.ret = e.requiredItems(int(a, 0)).map(\.id)
        case "sessionItems": o.ret = e.sessionItems(int(a, 0), lowEnergy: (a[1] as? Bool) ?? false).map(\.id)
        case "progressedWeight": o.ret = e.progressedWeight(e.exById(str(a, 0))!, dbl(a, 1))
        case "loEnergyW": o.ret = e.loEnergyW(dbl(a, 1))
        case "volOf": o.ret = e.volOf(str(a, 0), dbl(a, 1), reps(a, 2))
        case "lastOf": o.ret = obj(e.lastOf(str(a, 0)))
        case "weeklySets": o.ret = e.weeklySets(skip: strs(a, 0))
        case "patternsLost": o.ret = e.patternsLost(strs(a, 0))
        case "costOf": o.ret = obj(e.costOf(strs(a, 0)))
        case "idsForInjury": o.ret = PlanBuilder.idsForInjury(str(a, 0), e.plan)
        case "injuredIds": o.ret = e.injuredIds.sorted()
        case "gate": o.ret = obj(e.gate(view: int(a, 0)))
        case "nextDay": o.ret = e.nextDay()
        case "weekPlan": o.ret = obj(e.weekPlan())
        case "officeDays": o.ret = e.officeDays()
        case "weekStats": o.ret = obj(e.weekStats(str(a, 0)))
        case "streak": o.ret = e.streak()
        case "liftSlots": o.ret = obj(e.liftSlots(str(a, 0)))
        case "slotDone": o.ret = e.slotDone(str(a, 0), str(a, 1), str(a, 2))
        case "homeKey": o.ret = e.homeKey(slot: str(a, 0), date: str(a, 1))
        case "minutesFor": o.ret = e.minutesFor(int(a, 0))
        case "isLegs": o.ret = e.isLegs(int(a, 0))
        case "ringsLine": o.ret = e.ringsLine(e.weekStats(str(a, 0)))
        case "weekHeadline": o.ret = e.weekHeadline(e.weekStats(str(a, 0)))
        case "nextCard": o.ret = obj(e.nextCard(from: str(a, 0)))
        case "historyItems": o.ret = obj(e.historyItems())
        case "exCount": o.ret = e.exCount(e.db.history[int(a, 0)])
        case "warmIds": o.ret = e.warmIds(int(a, 0)).sorted()
        case "topSets": o.ret = obj(e.topSets(str(a, 0), weeks: int(a, 1)))
        case "progressLifts": o.ret = e.progressLifts().map(\.id)
        case "defaultProgressLift": o.ret = e.defaultProgressLift()
        case "progressPoints": o.ret = obj(e.progressPoints(lift: str(a, 0), weeks: int(a, 1)))
        case "progressWeeks":
            let p = e.progressWeeks()
            o.ret = ["stats": obj(p.stats) ?? NSNull(), "cardio": p.cardio, "steps": p.steps]
        case "rcHR": o.ret = obj(e.rcHR())
        case "hrMax": o.ret = e.hrMax()
        case "rcPhases": o.ret = obj(e.rcPhases(int(a, 0)))
        case "rcMinutes": o.ret = e.rcMinutes(int(a, 0))
        case "rcDefaultIntervals": o.ret = e.rcDefaultIntervals()
        case "zoneOf": o.ret = e.zoneOf(dbl(a, 0), dbl(a, 1))
        case "zoneRange": o.ret = e.zoneRange(int(a, 0), dbl(a, 1))
        case "cardioPlan": o.ret = obj(e.cardioPlan())
        case "lastActFor": o.ret = e.lastActFor(type: str(a, 0))
        case "recentCardio": o.ret = obj(e.recentCardio())
        case "agoLabel": o.ret = e.agoLabel(str(a, 0))
        case "cardioStats":
            let L = try JSONCompare.decode(LArg.self, from: a[0])
            o.ret = obj(e.cardioStats(samples: L.samples ?? [], elapsed: dbl(a, 1)))
        case "phaseAt":
            let L = try JSONCompare.decode(LArg.self, from: a[1])
            o.ret = obj(e.phaseAt(dbl(a, 0), n: L.n))
        case "hardDone":
            let L = try JSONCompare.decode(LArg.self, from: a[0])
            o.ret = e.hardDone(n: L.n, elapsed: dbl(a, 1))
        case "liftList": o.ret = e.liftList().map(\.id)
        case "shownEx": o.ret = e.shownEx(e.liftList()[int(a, 0)]).id
        case "curIdx": o.ret = e.curIdx()
        case "setsOf": o.ret = e.setsOf(e.liftList()[int(a, 0)])
        case "progOf": o.ret = obj(e.progOf(e.liftList()[int(a, 0)]))
        case "exState": o.ret = e.exState(e.liftList()[int(a, 0)])
        case "nextUp": o.ret = e.nextUp()?.id
        case "woBlocks": o.ret = obj(e.woBlocks())
        case "trendOf": o.ret = obj(e.trendOf(str(a, 0)))
        case "restFor": o.ret = e.restFor(e.liftList()[int(a, 0)])
        case "wOf": o.ret = e.wOf(e.exById(str(a, 0))!)
        case "warmupOptions": o.ret = obj(e.warmupOptions())
        case "applyInjury": toast(e.applyInjury(str(a, 0)))
        case "releaseInjury": toast(e.releaseInjury(str(a, 0)))
        case "logCardio":
            e.logCardio(str(a, 0), try cardioExtra(a[1]), date: a.count > 2 ? a[2] as? String : nil)
        case "applyImport": e.applyImport(try JSONCompare.decode(AppData.self, from: a[0]))
        case "newProfile": o.ret = obj(Engine.newProfile(name: str(a, 0), gender: str(a, 1)))
        case "begin": e.preLow = (pre["preLow"] as? Bool) ?? false; e.begin(day: int(a, 0))
        case "endSession":
            if let p = e.endSessionPrompt() { o.confirms.append(p.message); if !confirm { break } }
            _ = e.endSession()
        case "startCardio": e.startCardio(act: pre["pickAct"] as? String, reading: reading(pre))
        case "takeSample": o.ret = e.takeSample(reading: reading(pre))
        case "sessionSummary": o.ret = obj(e.sessionSummary(e.celebration!))
        default: throw NSError(domain: "fixture", code: 1, userInfo: [NSLocalizedDescriptionKey: "unknown fn \(fn)"])
        }
        return o
    }

    // MARK: click handlers: the controller each web button maps to

    func runClick(_ e: inout Engine, _ click: [String: Any], pre: [String: Any], confirm: Bool) throws -> Outcome {
        var o = Outcome()
        func toast(_ t: String?) { if let t = t, !t.isEmpty { o.toasts.append(t) } }
        func ask(_ m: String) -> Bool { o.confirms.append(m); return confirm }
        let ds = (click["dataset"] as? [String: String]) ?? [:], id = (click["id"] as? String) ?? ""
        let inputs = (pre["inputs"] as? [String: String]) ?? [:]
        func num(_ k: String) -> Double { Double(inputs[k] ?? "") ?? 0 }
        func endSessionFlow() {
            if let p = e.endSessionPrompt() { if !ask(p.message) { return } }
            _ = e.endSession()
        }
        let discardMsg = "Discard this workout? Nothing will be saved."

        if click["sheet"] as? Bool == true {
            if let v = ds["wwu"] { let p = v.split(separator: "|").map { Double($0)! }; e.addWarmup(w: p[0], r: p[1]) }
            else if let to = ds["swapto"] { toast(e.applySwap(to: to)) }
            else if let m = ds["menu"] {
                switch m {
                case "finish": endSessionFlow()
                case "low": toast(e.toggleLighterDay())
                case "discard": if ask(discardMsg) { e.discardWorkout() }
                default: break
                }
            }
            else if let why = ds["why"] { toast(e.skipToday(why: why)) }
            else if let t = ds["walk"] { toast(e.logWalk(type: t, min: num("#wMin"))) }
            else if id == "cSave" {
                let p = ds["c"]!.split(separator: "|").map(String.init)
                e.editCardio(date: p[0], type: p[1], value: num("#cVal"))
            }
            else if id == "cDel" {
                let p = ds["c"]!.split(separator: "|").map(String.init)
                if ask("Delete this entry?") { e.deleteCardio(date: p[0], type: p[1]) }
            }
            else if ds["wo"] == "addlift" { e.begin(day: e.nextDay()) }
            else if ds["wo"] == "endsess" { toast("Session saved") }
            return o
        }

        switch ds["wo"] {
        case "open": toast(e.openEx(Int(ds["i"]!)!))
        case "rep": e.adjustReps(Int(ds["i"]!)!)
        case "log": toast(e.logWoSet())
        case "undo": e.undoSet()
        case "w": e.adjustWeight(Int(ds["i"]!)!)
        case "addset": toast(e.addExtraSet())
        case "wu": e.toggleWarmup(Int(ds["i"]!)!)
        case "wudel": e.removeWarmup(Int(ds["i"]!)!)
        case "busy": e.markBusy().toasts.forEach { toast($0) }
        case "exdone":
            if let p = e.completeExercisePrompt() { if !ask(p) { break }; e.completeExercise(confirmedPartial: true) }
            else { e.completeExercise(confirmedPartial: false) }
        case "sdiscard": if ask(discardMsg) { e.discardWorkout() }
        case "cdiscard": if ask("Discard this cardio session? Nothing will be saved.") { e.discardCardio() }
        case "cdone":
            let payload = e.endCardio(reading: reading(pre))
            e.recordHealthResult(saved: (pre["saved"] as? Bool) ?? false)
            o.ret = obj(payload)
        default:
            if let d = ds["logsteps"] { toast(e.logSteps(date: d, input: inputs["#stepsIn"] ?? "")) }
            else if let s = ds["logmin"] { toast(e.logMinutes(slot: s, min: num("#minIn"))) }
            else if let v = ds["age"] { e.adjustAge(Int(v)!) }
            else if let v = ds["off"] { e.toggleOfficeDay(Int(v)!) }
            else if let k = ds["inj"] {
                if e.db.injuries.contains(where: { $0.key == k }) { toast(e.releaseInjury(k)) }
                else if ask(e.injuryPrompt(k)) { toast(e.applyInjury(k)) }
            }
            else if let g = ds["gender"] {
                if g != e.profile.gender, ask(e.genderPrompt(g)) { toast(e.setGender(g)) }
            }
            else {
                switch id {
                case "woList": e.backToList()
                case "lowTg": e.togglePreviewLighter()
                case "endBtn": endSessionFlow()
                case "skipJumps": e.skipJumps()
                case "jumpsDone":
                    let sets = (pre["jumpSets"] as? [String: Int]) ?? [:]
                    toast(e.completeJumps(sets: sets))
                case "beginBtn":
                    let day = (pre["previewDay"] as? NSNumber)?.intValue ?? 1
                    switch e.beginCheck(day: day) {
                    case .alreadyOpen(let t): toast(t)
                    case .confirm(let m): if ask(m) { e.begin(day: day) }
                    case .ok: e.begin(day: day)
                    }
                case "homeDone": toast(e.homeDone(ds["d"]!))
                case "undoSkip": toast(e.undoSkip(ds["d"]!))
                case "detJumps": e.toggleSessionJumps((pre["detailIdx"] as! NSNumber).intValue)
                case "delSess":
                    if ask(e.deleteSessionPrompt) { toast(e.deleteSession((pre["detailIdx"] as! NSNumber).intValue)) }
                case "addWaist": toast(e.addWaist(cm: num("#waistIn")))
                case "resetBtn": if ask(e.resetPrompt) { toast(e.reset()) }
                default: throw NSError(domain: "fixture", code: 2, userInfo: [NSLocalizedDescriptionKey: "unmapped click \(click)"])
                }
            }
        }
        return o
    }
}
