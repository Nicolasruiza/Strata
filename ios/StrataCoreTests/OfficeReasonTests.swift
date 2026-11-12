import XCTest
@testable import StrataCore

final class OfficeReasonTests: XCTestCase {
    // 2026-11-11 is a Wednesday: a lift day, no office days configured.
    private func engine() -> Engine {
        let profile = Profile(name: "Nico", initials: "NI", gender: "male", plan: "nr", bw: 194, exp: "trained")
        let now = ISO8601DateFormatter().date(from: "2026-11-11T12:00:00Z")!.timeIntervalSince1970 * 1_000
        return Engine(profile: profile, db: AppData.fresh(), nowMs: now, tz: TimeZone(secondsFromGMT: 0)!)
    }

    func testOfficeIsOneOfTheCantTrainReasons() {
        XCTAssertTrue(Catalog.shared.skipWhy.contains { $0[0] == "office" })
    }

    func testGoingToTheOfficeOnALiftDaySkipsItAndSuggestsAWalk() {
        var e = engine()
        let toast = e.skipToday(why: "office")
        XCTAssertTrue(toast.contains("7,000"))
        let sk = e.skipOn(e.today)
        XCTAssertEqual(sk?.why, "office")
        XCTAssertEqual(sk?.key, "walk")
        XCTAssertNotNil(sk?.day)                                   // the rotation waits, like any skipped lift
        e.logSteps(date: e.today, input: "8200")
        XCTAssertNotNil(e.cardioOn(e.today, "office"))             // steps count toward Heart
        XCTAssertEqual(e.undoSkip(e.today), "Back on the plan")
        XCTAssertNil(e.skipOn(e.today))
    }
}
