import XCTest
@testable import StrataCore

final class SlotOverrideTests: XCTestCase {
    /// Sunday 15 Nov 2026 (a "walk" day in the base plan), Saturday's lift not done.
    private func engine(plan: String = "nr", gender: String = "male") -> Engine {
        let profile = Profile(name: "Nico", initials: "NI", gender: gender, plan: plan, bw: 194, exp: "trained")
        let now = ISO8601DateFormatter().date(from: "2026-11-15T15:00:00Z")!.timeIntervalSince1970 * 1_000
        return Engine(profile: profile, db: AppData.fresh(), nowMs: now, tz: TimeZone(secondsFromGMT: 0)!)
    }

    func testPickingSomethingElseReplacesTodaysSlotOnlyForThatDate() {
        var e = engine()
        let mon = Dates.mondayOf(e.today)
        XCTAssertEqual(e.weekPlan(mon)[0], "walk")
        e.setSlotOver(e.today, "lift")
        XCTAssertEqual(e.weekPlan(mon)[0], "lift")
        XCTAssertEqual(e.weekPlan(mon)[1], "lift")           // Monday untouched
        XCTAssertEqual(e.liftSlots(mon)[0]?.status, "planned")
        e.clearSlotOver(e.today)
        XCTAssertEqual(e.weekPlan(mon)[0], "walk")
        XCTAssertNil(e.db.slotOver)
    }

    func testPickingTheBaseSlotClearsTheOverride() {
        var e = engine()
        e.setSlotOver(e.today, "z2")
        XCTAssertNotNil(e.db.slotOver)
        e.setSlotOver(e.today, "walk")
        XCTAssertNil(e.db.slotOver)
    }

    func testAMissedLiftIsOwedUntilTheMuscleRingCloses() {
        var e = engine()
        XCTAssertTrue(e.liftOwed(Dates.mondayOf(e.today)))
        e.setSlotOver(e.today, "lift")
        XCTAssertTrue(e.liftOwed(Dates.mondayOf(e.today)))
        let data = try! JSONEncoder().encode(e.db)
        XCTAssertEqual(try! JSONDecoder().decode(AppData.self, from: data).slotOver?[e.today], "lift")
    }

    func testSwapOptionsHideTheSameExerciseUnderAnotherName() {
        let e = engine()
        for (id, hidden) in Engine.altSame {
            guard let ex = e.ap.all.first(where: { $0.id == id }) else { continue }
            XCTAssertFalse(e.swapOptions(ex).contains { hidden.contains($0.id) }, id)
        }
        for ex in e.ap.all {
            let n = Fmt.cleanN(ex.n).lowercased()
            XCTAssertFalse(e.swapOptions(ex).contains { Fmt.cleanN($0.n).lowercased() == n }, ex.id)
        }
    }
}
