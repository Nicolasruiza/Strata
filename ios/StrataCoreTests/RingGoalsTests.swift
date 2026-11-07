import XCTest
@testable import StrataCore

/// Ring goals are fixed and can be exceeded: a missed day never costs the week.
final class RingGoalsTests: XCTestCase {
    private func engine(lifts: [String], cardio: [CardioEntry] = []) -> Engine {
        let profile = Profile(name: "Nico", initials: "NI", gender: "male", plan: "nr", bw: 194, exp: "trained")
        var db = AppData.fresh()
        db.history = lifts.map { Session(date: $0, day: 1, vol: nil, entries: OrderedDict<Entry>(), lowEnergy: nil, min: nil, swaps: nil) }
        db.cardio = cardio
        let now = ISO8601DateFormatter().date(from: "2026-11-07T12:00:00Z")!.timeIntervalSince1970 * 1_000
        return Engine(profile: profile, db: db, nowMs: now, tz: TimeZone(secondsFromGMT: 0)!)
    }
    private let mon = "2026-11-02"

    func testGoalsAreFixed() {
        let st = engine(lifts: []).weekStats(mon)
        XCTAssertEqual([st.mt, st.ht, st.bt], [3, 3, 2])
        XCTAssertEqual([st.mt, st.ht, st.bt], [Config.RingGoals.muscle, Config.RingGoals.heart, Config.RingGoals.bone])
    }

    func testThreeLiftsCloseMuscleEvenWhenAFourthIsSkipped() {
        let st = engine(lifts: ["2026-11-02", "2026-11-04", "2026-11-06"]).weekStats(mon)
        XCTAssertEqual(st.m, 3)
        XCTAssertTrue(st.closed[0])
    }

    func testRingsCountPastTheGoal() {
        let st = engine(lifts: ["2026-11-02", "2026-11-03", "2026-11-04", "2026-11-06", "2026-11-07"]).weekStats(mon)
        XCTAssertEqual(st.m, 5)          // not capped at 3
        XCTAssertTrue(st.closed[0])
    }

    func testTwoLiftsLeaveOneToGo() {
        let e = engine(lifts: ["2026-11-02", "2026-11-04"])
        XCTAssertFalse(e.weekStats(mon).closed[0])
        XCTAssertTrue(e.ringsLine(e.weekStats(mon)).contains("1 more lift"))
    }

    func testAnyThreeHeartSessionsCloseHeart() {
        let c = ["2026-11-02", "2026-11-04", "2026-11-08"].map { CardioEntry(date: $0, type: "walk", min: 45) }
        XCTAssertTrue(engine(lifts: [], cardio: c).weekStats(mon).closed[1])
    }
}
