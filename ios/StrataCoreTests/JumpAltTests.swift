import XCTest
@testable import StrataCore

final class JumpAltTests: XCTestCase {
    private func engine() -> Engine {
        let profile = Profile(name: "Nico", initials: "NI", gender: "male", plan: "nr", bw: 194, exp: "trained")
        let now = ISO8601DateFormatter().date(from: "2026-11-10T12:00:00Z")!.timeIntervalSince1970 * 1_000
        return Engine(profile: profile, db: AppData.fresh(), nowMs: now, tz: TimeZone(secondsFromGMT: 0)!)
    }

    func testStepUpsAreTheDefaultNotBoxJumps() {
        let e = engine()
        XCTAssertEqual(e.jumpAlt.id, "stepup")
        XCTAssertTrue(e.jumpsPlanText.contains("Fast step-ups"))
        XCTAssertFalse(e.jumpsPlanText.contains("Box"))
    }

    func testPickingAnAlternativeSticksAndUnknownIdsAreIgnored() throws {
        var e = engine()
        e.setJumpAlt("box")
        XCTAssertEqual(e.jumpAlt.id, "box")
        e.setJumpAlt("nope")
        XCTAssertEqual(e.jumpAlt.id, "box")
        let data = try JSONEncoder().encode(e.db)
        XCTAssertEqual(try JSONDecoder().decode(AppData.self, from: data).jumpAlt, "box")
    }

    func testEveryAlternativeHasASetPlanAndRest() {
        for a in Config.Jumps.alts { XCTAssertGreaterThan(a.sets, 0); XCTAssertGreaterThan(a.rest, 0); XCTAssertFalse(a.how.isEmpty) }
    }
}
