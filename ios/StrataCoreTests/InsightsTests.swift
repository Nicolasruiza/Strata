import XCTest
@testable import StrataCore

final class InsightsTests: XCTestCase {
    private func engine(cardio: [CardioEntry] = []) -> Engine {
        let profile = Profile(name: "Nico", initials: "NI", gender: "male", plan: "nr", bw: 194, exp: "trained")
        var data = AppData.fresh()
        data.cardio = cardio
        let now = ISO8601DateFormatter().date(from: "2026-11-04T12:00:00Z")!.timeIntervalSince1970 * 1_000
        return Engine(profile: profile, db: data, nowMs: now, tz: TimeZone(secondsFromGMT: 0)!)
    }

    func testShortSleepAndLowStepsAreFlagged() {
        let found = engine().insights(health: HealthSignals(sleepHours: [5.5, 6, 6.2], steps: [4_000, 5_000, 6_000]))
        XCTAssertEqual(found.map(\.kind), [.sleep, .steps, .remaining])
    }

    func testEnoughSleepAndStepsAreQuiet() {
        let found = engine().insights(health: HealthSignals(sleepHours: [7.5, 8, 7.2], steps: [9_000, 10_000, 8_000]))
        XCTAssertEqual(found.map(\.kind), [.remaining])
    }

    func testTooLittleDataIsNotJudged() {
        let found = engine().insights(health: HealthSignals(sleepHours: [4], steps: [1_000]))
        XCTAssertEqual(found.map(\.kind), [.remaining])
    }

    func testBoneSkippedTwoWeeksRunning() {
        // History starts three weeks back and has no jump days since.
        let found = engine(cardio: [CardioEntry(date: "2026-10-12", type: "z2", min: 45)]).insights(health: HealthSignals())
        XCTAssertTrue(found.contains { $0.kind == .bone })
    }

    func testNoRingInsightWithoutEnoughHistory() {
        let found = engine(cardio: [CardioEntry(date: "2026-11-02", type: "z2", min: 45)]).insights(health: HealthSignals())
        XCTAssertFalse(found.contains { $0.kind == .bone })
    }
}
