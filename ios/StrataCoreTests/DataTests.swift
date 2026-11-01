import XCTest
@testable import StrataCore

/// Storage: the JSON a web export holds loads unchanged, saves back with the same
/// content, and keeps the order lifts were logged in.
final class DataTests: XCTestCase {
    let web = """
    {"app":"strata","profile":"me","profileName":"Nico","planKey":"nr",
     "next":{"bb_press":140},"history":[
       {"date":"2026-10-26","day":1,"vol":3000,"min":48,"lowEnergy":false,"swaps":{},
        "entries":{"lat_pull":{"w":75,"reps":[8,8,8]},"bb_press":{"w":135,"reps":[6,6,null]},"cbl_row":{"w":70,"reps":[10,10,10]},"db_curl":{"w":30,"reps":[12,12,12]}}}],
     "active":null,"holds":{"rdl":1},"cycleStarts":[],"focus":null,"injuries":[],"cycleAnchor":null,
     "cardio":[{"date":"2026-10-27","type":"z2","min":50,"act":"treadmill"}],"age":40,"demoSensors":true,
     "live":null}
    """

    func testWebExportLoadsAndKeepsEntryOrder() throws {
        let db = try AppData.load(from: Data(web.utf8))
        XCTAssertEqual(db.history.count, 1)
        XCTAssertEqual(db.history[0].entries.keys, ["lat_pull", "bb_press", "cbl_row", "db_curl"])
        XCTAssertEqual(db.history[0].entries["bb_press"]?.reps, [6, 6, nil])
        XCTAssertEqual(db.age, 40)
        XCTAssertEqual(db.holds["rdl"], 1)
    }

    func testSaveReloadKeepsContentAndOrder() throws {
        let db = try AppData.load(from: Data(web.utf8))
        let again = try AppData.load(from: try db.jsonData())
        XCTAssertEqual(db, again)
        XCTAssertEqual(again.history[0].entries.keys, ["lat_pull", "bb_press", "cbl_row", "db_curl"])
        let text = String(decoding: try db.jsonData(), as: UTF8.self)
        XCTAssertFalse(text.contains("demoSensors"), "the web's demo switch is never written back")
        let a = text.range(of: "\"lat_pull\"")!.lowerBound, b = text.range(of: "\"bb_press\"")!.lowerBound
        XCTAssertLessThan(a, b, "entries are written in logged order")
    }

    func testExportHasTheWebHeaderAndImportsBack() throws {
        let nr = Profile(name: "Nico", initials: "NI", gender: "male", plan: "nr", bw: 194, exp: "trained")
        let e = Engine(profile: nr, db: try AppData.load(from: Data(web.utf8)), nowMs: 1_793_000_000_000, tz: TimeZone(identifier: "America/Toronto")!)
        let data = try e.exportData()
        let header = try JSONDecoder().decode(ExportHeader.self, from: data)
        XCTAssertEqual(header.app, "strata"); XCTAssertEqual(header.profile, "me")
        XCTAssertEqual(header.profileName, "Nico"); XCTAssertEqual(header.planKey, "nr")
        XCTAssertEqual(try AppData.load(from: data), e.db)
        XCTAssertEqual(e.exportFileName(), "strata-nico-\(e.today).json")
    }

    func testImportConfirmationCopy() {
        let nr = Profile(name: "Nico", initials: "NI", gender: "male", plan: "nr", bw: 194, exp: "trained")
        let e = Engine(profile: nr, db: AppData.fresh(), nowMs: 0, tz: TimeZone(identifier: "UTC")!)
        XCTAssertNil(e.importPrompt(ExportHeader(app: "strata", profile: "me", profileName: "Nico", planKey: "nr"), quiet: false))
        XCTAssertEqual(e.importPrompt(ExportHeader(app: nil, profile: nil, profileName: "Sofia", planKey: "sa"), quiet: false),
                       "This file is from Sofia. Import it into Nico anyway? Nico's current data will be replaced.")
        XCTAssertEqual(e.importPrompt(ExportHeader(app: nil, profile: nil, profileName: nil, planKey: nil), quiet: false),
                       "Replace Nico's data with this file?")
        XCTAssertNil(e.importPrompt(ExportHeader(app: nil, profile: nil, profileName: nil, planKey: "sa"), quiet: true))
    }

    func testSeedDefaults() {
        XCTAssertEqual(AppData.default(planKey: "nr").holds, ["rdl": 1])
        XCTAssertEqual(AppData.default(planKey: "sa").holds, [:])
        XCTAssertEqual(AppData.fresh().holds, [:])
    }

    func testNoDemoOrSampleDataInTheLibrary() throws {
        // The app starts empty: no history, no live session, nothing seeded.
        let d = AppData.fresh()
        XCTAssertTrue(d.history.isEmpty && d.cardio.isEmpty && d.live == nil && d.active == nil)
    }
}
