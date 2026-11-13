import XCTest
@testable import StrataCore

final class FocusDockTests: XCTestCase {
    private func started() -> Engine {
        let profile = Profile(name: "Nico", initials: "NI", gender: "male", plan: "nr", bw: 194, exp: "trained")
        let now = ISO8601DateFormatter().date(from: "2026-11-10T12:00:00Z")!.timeIntervalSince1970 * 1_000
        var e = Engine(profile: profile, db: AppData.fresh(), nowMs: now, tz: TimeZone(secondsFromGMT: 0)!)
        e.begin(day: 1)
        _ = e.openEx(0)
        return e
    }

    func testMarkAllCompleteFillsEverySetAndReturnsToTheList() {
        var e = started()
        let orig = e.liftList()[e.curIdx()], n = e.setsOf(orig)
        e.logWoSet()
        e.markAllComplete()
        let p = e.progOf(orig)!
        XCTAssertEqual(p.reps.count, n)
        XCTAssertEqual(e.db.active!.entries[e.shownEx(orig).id]?.reps.count, n)
        XCTAssertEqual(e.db.active!.view, "list")
        XCTAssertNil(e.rest)
    }

    func testResetClearsLoggedSetsButStaysOnTheExercise() {
        var e = started()
        let orig = e.liftList()[e.curIdx()]
        e.logWoSet(); e.addExtraSet()
        e.resetExercise()
        XCTAssertNil(e.progOf(orig))
        XCTAssertEqual(e.db.active!.view, "focus")
        XCTAssertEqual(e.setsOf(orig), orig.setCount)
    }
}
