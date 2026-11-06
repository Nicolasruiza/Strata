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

    func testEveryMessageFitsTheFixedCard() {
        // Worst case: every insight at once (old history, nothing closed, all health signals bad).
        let cardio = [CardioEntry(date: "2026-09-01", type: "z2", min: 45)]
        let signals = HealthSignals(sleepHours: [4, 5, 4.5], steps: [1_000, 2_000, 3_000],
                                    vo2Recent: [30], vo2Prior: [45])
        let found = engine(cardio: cardio).insights(health: signals)
        XCTAssertGreaterThanOrEqual(found.count, 5)
        for i in found {
            XCTAssertLessThanOrEqual(i.title.count, Config.Insights.maxTitleChars, i.title)
            XCTAssertLessThanOrEqual(i.body.count, Config.Insights.maxBodyChars, i.body)
        }
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

    func testVo2DropIsFlaggedButSmallChangeIsNot() {
        let drop = engine().insights(health: HealthSignals(vo2Recent: [42.0, 42.4], vo2Prior: [44.0, 44.4]))
        XCTAssertTrue(drop.contains { $0.kind == .vo2 })
        let flat = engine().insights(health: HealthSignals(vo2Recent: [43.8], vo2Prior: [44.0]))
        XCTAssertFalse(flat.contains { $0.kind == .vo2 })
        let noPrior = engine().insights(health: HealthSignals(vo2Recent: [40]))
        XCTAssertFalse(noPrior.contains { $0.kind == .vo2 })
    }

    func testVo2RatingByAgeAndSex() {
        // 37 is Poor for a man 30-49 (Fair starts at 40.5 / 38.5), Good for a woman 30-39 (37.8).
        XCTAssertEqual(Engine.vo2Rating(37, age: 37, gender: "male")?.name, "Poor")
        XCTAssertEqual(Engine.vo2Rating(37, age: 45, gender: "male")?.nextAt, 38.5)
        XCTAssertEqual(Engine.vo2Rating(37.8, age: 35, gender: "female")?.name, "Good")
        XCTAssertEqual(Engine.vo2Rating(60, age: 25, gender: "male")?.name, "Superior")
        XCTAssertNil(Engine.vo2Rating(60, age: 25, gender: nil))
        XCTAssertEqual(Engine.vo2Rating(40, age: 95, gender: "male")?.band, "70–79")
    }
}
