import XCTest
@testable import StrataCore

/// Waist readings come in from Apple Health without ever overwriting a number typed in Strata.
final class WaistTests: XCTestCase {
    private func engine(_ waist: [Waist]? = nil) -> Engine {
        let profile = Profile(name: "Nico", initials: "NI", gender: "male", plan: "nr", bw: 194, exp: "trained")
        var db = AppData.fresh(); db.waist = waist
        let now = ISO8601DateFormatter().date(from: "2026-11-07T12:00:00Z")!.timeIntervalSince1970 * 1_000
        return Engine(profile: profile, db: db, nowMs: now, tz: TimeZone(secondsFromGMT: 0)!)
    }

    func testImportAddsNewDaysSortedAndRounded() {
        var e = engine([Waist(date: "2026-11-01", cm: 90)])
        XCTAssertTrue(e.importWaist(["2026-10-15": 91.04, "2026-11-05": 89.46]))
        XCTAssertEqual(e.db.waist?.map(\.date), ["2026-10-15", "2026-11-01", "2026-11-05"])
        XCTAssertEqual(e.db.waist?.map(\.cm), [91.0, 90, 89.5])
    }

    func testImportNeverOverwritesADayYouAlreadyHave() {
        var e = engine([Waist(date: "2026-11-01", cm: 90)])
        XCTAssertFalse(e.importWaist(["2026-11-01": 80]))
        XCTAssertEqual(e.db.waist?.first?.cm, 90)
    }

    func testImportIgnoresFutureAndImplausibleReadings() {
        var e = engine()
        XCTAssertFalse(e.importWaist(["2026-11-09": 90, "2026-11-01": 5, "2026-10-01": 400]))
        XCTAssertNil(e.db.waist)
    }
}
