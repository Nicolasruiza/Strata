import XCTest
@testable import StrataCore

/// A decent walking average closes Heart on its own; sessions still count.
final class WalkingRingTests: XCTestCase {
    private let mon = "2026-11-02"          // the week of Mon Nov 2; "today" is Sat Nov 7
    private func engine(steps: [String: Int]) -> Engine {
        let profile = Profile(name: "Nico", initials: "NI", gender: "male", plan: "nr", bw: 194, exp: "trained")
        var db = AppData.fresh(); db.steps = steps
        let now = ISO8601DateFormatter().date(from: "2026-11-07T12:00:00Z")!.timeIntervalSince1970 * 1_000
        return Engine(profile: profile, db: db, nowMs: now, tz: TimeZone(secondsFromGMT: 0)!)
    }

    func testAverageOfSevenThousandClosesHeart() {
        let e = engine(steps: ["2026-11-02": 9_000, "2026-11-03": 6_000, "2026-11-04": 8_000, "2026-11-05": 5_000, "2026-11-06": 7_500])
        let st = e.weekStats(mon)
        XCTAssertEqual(st.walkAvg, 7_100)
        XCTAssertTrue(st.closed[1])
        XCTAssertTrue(st.closedByWalking)
    }

    func testLowAverageLeavesHeartOpen() {
        let e = engine(steps: ["2026-11-02": 4_000, "2026-11-03": 5_000, "2026-11-04": 6_000, "2026-11-05": 5_000])
        let st = e.weekStats(mon)
        XCTAssertEqual(st.walkAvg, 5_000)
        XCTAssertFalse(st.closed[1])
    }

    func testNeedsFourFinishedDays() {
        let e = engine(steps: ["2026-11-02": 20_000, "2026-11-03": 20_000, "2026-11-04": 20_000])
        XCTAssertNil(e.weekStats(mon).walkAvg)
        XCTAssertFalse(e.weekStats(mon).closed[1])
    }

    func testTodayIsLeftOutBecauseItIsStillBeingWalked() {
        let e = engine(steps: ["2026-11-02": 8_000, "2026-11-03": 8_000, "2026-11-04": 8_000, "2026-11-05": 8_000, "2026-11-07": 300])
        XCTAssertEqual(e.weekStats(mon).walkAvg, 8_000)
    }

    func testRecordingKeepsEveryDayAndDropsOldOnes() {
        var e = engine(steps: ["2026-01-01": 5_000])
        XCTAssertTrue(e.recordDailySteps(["2026-11-06": 6_000, "2026-11-08": 9_999, "2026-11-05": 0]))
        XCTAssertEqual(e.db.steps, ["2026-11-06": 6_000])      // future and empty days ignored, old day pruned
        XCTAssertFalse(e.recordDailySteps(["2026-11-06": 6_000]))
    }
}
