import XCTest
@testable import StrataCore

final class CatalogAndFormatTests: XCTestCase {
    func fixture(_ name: String) throws -> Any {
        let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")!
        return try JSONSerialization.jsonObject(with: Data(contentsOf: url), options: [.fragmentsAllowed])
    }

    /// The generated catalog, re-encoded, equals what the web source holds.
    func testCatalogMatchesWeb() throws {
        let web = try fixture("catalog") as! [String: Any]
        let swift = JSONCompare.object(Catalog.shared) as! [String: Any]
        for k in web.keys.sorted() {
            XCTAssertNil(JSONCompare.diff(web[k], swift[k], path: k), "catalog.\(k)")
        }
    }

    /// `WCFG` is hand-written in Swift (`Config.workout`): it must equal the web's.
    func testWorkoutConfigMatchesWCFG() throws {
        let web = (try fixture("catalog") as! [String: Any])["wcfg"]
        XCTAssertNil(JSONCompare.diff(web, JSONCompare.object(Config.workout)))
    }

    func testHandWrittenZoneTablesMatchWeb() throws {
        let web = try fixture("catalog") as! [String: Any]
        XCTAssertEqual(web["zname"] as? [String], Config.zoneNames)
        XCTAssertEqual(web["zcol"] as? [String], Config.zoneColors)
        XCTAssertEqual((web["nagDays"] as? NSNumber)?.intValue, Catalog.shared.nagDays)
    }

    func testFormatAndDateFixtures() throws {
        let rows = try fixture("format") as! [[String: Any]]
        let nr = Profile(name: "Nico", initials: "NI", gender: "male", plan: "nr", bw: 194, exp: "trained")
        let sa = Profile(name: "Sofia", initials: "SO", gender: "female", plan: "sa", bw: 132, exp: "new")
        let e = Engine(profile: nr, db: AppData.fresh(), nowMs: 0, tz: TimeZone(identifier: "America/Toronto")!)
        var failures: [String] = []
        for (n, row) in rows.enumerated() {
            let fn = row["fn"] as! String, a = row["args"] as! [Any]
            func s(_ i: Int) -> String { a[i] as? String ?? "" }
            func d(_ i: Int) -> Double { (a[i] as? NSNumber)?.doubleValue ?? 0 }
            func ex(_ i: Int) -> Ex { e.exById(s(i))! }
            var got: Any?
            switch fn {
            case "cleanN": got = Fmt.cleanN(s(0))
            case "fmtD":
                var o = Dates.FmtOpts()
                if let m = a[1] as? [String: Any] {
                    o.weekday = (m["weekday"] as? String).map { $0 == "long" ? .long : .short }
                    o.month = (m["month"] as? String).map { $0 == "long" ? .long : .short }
                    o.day = m["day"] != nil
                    o.year = m["year"] != nil
                    got = Dates.fmtD(s(0), o)
                } else { got = Dates.fmtD(s(0)) }
            case "addDays": got = Dates.addDays(s(0), Int(d(1)))
            case "dayDiff": got = Dates.dayDiff(s(0), s(1))
            case "weekday": got = Dates.weekday(s(0))
            case "mondayOf": got = Dates.mondayOf(s(0))
            case "weekDates": got = Dates.weekDates(s(0))
            case "nf": got = Fmt.nf(d(0))
            case "mmss": got = Fmt.mmss(d(0))
            case "fmtSets": got = Fmt.fmtSets(d(0))
            case "plateTxt": got = Fmt.plateTxt(ex(0), d(1))
            case "wLbl": got = Fmt.wLbl(ex(0), d(1))
            case "repLbl": got = Fmt.repLbl(ex(0), a[1] is NSNull ? nil : d(1))
            case "perLeg": got = Fmt.perLeg(ex(0))
            case "isSec": got = Fmt.isSec(ex(0))
            case "ytURL": got = Fmt.formVideoURL(id: s(0), name: s(1), qmapKey: s(2))
            case "imgOf": got = Catalog.shared.imageName(of: s(0))
            case "cueOf": got = Catalog.shared.cue(of: s(0))
            case "conceptKey": got = Catalog.shared.conceptKey(s(0))
            case "metaOf": got = JSONCompare.object(Catalog.shared.meta(of: s(0)))
            case "exById": got = e.exById(s(0)).flatMap { JSONCompare.object($0) }
            default: failures.append("#\(n) unknown fn \(fn)"); continue
            }
            if let diff = JSONCompare.diff(row["ret"], got) { failures.append("#\(n) \(fn)\(a): \(diff)") }
        }
        _ = sa
        XCTAssertTrue(failures.isEmpty, "\(failures.count) format fixtures differ:\n" + failures.prefix(25).joined(separator: "\n"))
    }
}
