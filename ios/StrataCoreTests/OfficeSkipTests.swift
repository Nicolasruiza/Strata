import XCTest
@testable import StrataCore

final class OfficeSkipTests: XCTestCase {
    // 2026-11-12 is a Thursday.
    private func engine() -> Engine {
        let profile = Profile(name: "Nico", initials: "NI", gender: "male", plan: "nr", bw: 194, exp: "trained")
        var db = AppData.fresh(); db.officeDays = [2, 4]
        let now = ISO8601DateFormatter().date(from: "2026-11-12T12:00:00Z")!.timeIntervalSince1970 * 1_000
        return Engine(profile: profile, db: db, nowMs: now, tz: TimeZone(secondsFromGMT: 0)!)
    }

    func testNotGoingTurnsThursdayIntoAZoneTwoWalkOnlyThatWeek() {
        var e = engine()
        XCTAssertEqual(e.weekPlan()[4], "office")
        XCTAssertNotNil(e.skipOffice("2026-11-12"))
        XCTAssertEqual(e.weekPlan()[4], "z2")
        XCTAssertEqual(e.weekPlan()[2], "office")                                  // Tuesday untouched
        XCTAssertEqual(e.weekPlan(Dates.addDays(Dates.mondayOf(e.today), 7))[4], "office")   // next Thursday untouched
        XCTAssertTrue(e.officeSkipped("2026-11-12"))
    }

    func testUndoAndGuards() {
        var e = engine()
        XCTAssertNil(e.skipOffice("2026-11-11"))                                   // Wednesday is a lift day, not office: ignored
        e.skipOffice("2026-11-12"); e.undoSkipOffice("2026-11-12")
        XCTAssertEqual(e.weekPlan()[4], "office")
        XCTAssertNil(e.db.officeOff)
        e.logSteps(date: "2026-11-12", input: "9000")
        XCTAssertNil(e.skipOffice("2026-11-12"))                                   // already logged steps
    }

    func testStoredDataRoundTrips() throws {
        var e = engine(); e.skipOffice("2026-11-12")
        let back = try JSONDecoder().decode(AppData.self, from: JSONEncoder().encode(e.db))
        XCTAssertEqual(back.officeOff, ["2026-11-12"])
    }
}
