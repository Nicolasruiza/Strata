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

final class JumpsProgressTests: XCTestCase {
    func testLoggedSetsSurviveLeavingAndComingBack() {
        let profile = Profile(name: "Nico", initials: "NI", gender: "male", plan: "nr", bw: 194, exp: "trained")
        var e = Engine(profile: profile, db: AppData.fresh(), nowMs: 1_793_000_000_000, tz: TimeZone(secondsFromGMT: 0)!)
        e.begin(day: 4)
        e.setJumpSets("pogo", 3); e.setJumpSets("sl_rdl", 2)
        _ = e.completeJumps(sets: e.db.active!.jumps ?? [:])
        e.db.active!.jumpsSeen = 0                       // reopening the warm-up from the overview
        XCTAssertEqual(e.db.active?.jumps, ["pogo": 3, "sl_rdl": 2])
        e.setJumpSets("pogo", 2)
        XCTAssertEqual(e.db.active?.jumps?["pogo"], 2)
        e.setJumpSets("pogo", 0); e.setJumpSets("sl_rdl", 0)
        XCTAssertNil(e.db.active?.jumps)
    }
}
