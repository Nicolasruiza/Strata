import XCTest
@testable import StrataCore

final class JumpsTests: XCTestCase {
    private func engine() -> Engine {
        let profile = Profile(name: "Nico", initials: "NI", gender: "male", plan: "nr", bw: 194, exp: "trained")
        let now = ISO8601DateFormatter().date(from: "2026-11-07T12:00:00Z")!.timeIntervalSince1970 * 1_000
        var e = Engine(profile: profile, db: AppData.fresh(), nowMs: now, tz: TimeZone(secondsFromGMT: 0)!)
        e.begin(day: 4)   // Legs B: has the single-leg RDL warm-up
        return e
    }

    func testWarmupLoadIsSavedAndRemembered() {
        var e = engine()
        _ = e.completeJumps(sets: ["sl_rdl": 2], weights: ["sl_rdl": 25])
        XCTAssertEqual(e.db.active?.entries["sl_rdl"]?.w, 25)
        XCTAssertEqual(e.db.active?.entries["sl_rdl"]?.reps.count, 2)
    }

    func testBodyweightWhenNoLoadGiven() {
        var e = engine()
        _ = e.completeJumps(sets: ["sl_rdl": 1])
        XCTAssertEqual(e.db.active?.entries["sl_rdl"]?.w, 0)
    }
}
