import XCTest
@testable import StrataCore

final class DumbbellMaxTests: XCTestCase {
    private func engine() -> Engine {
        let profile = Profile(name: "Nico", initials: "NI", gender: "male", plan: "nr", bw: 194, exp: "trained")
        let now = ISO8601DateFormatter().date(from: "2026-11-10T12:00:00Z")!.timeIntervalSince1970 * 1_000
        return Engine(profile: profile, db: AppData.fresh(), nowMs: now, tz: TimeZone(secondsFromGMT: 0)!)
    }
    private let goblet = Ex(id: "gob_squat", n: "Goblet squat", r: 8, w: 50, inc: 5, key: 1)
    private let barbell = Ex(id: "bb_press", n: "Barbell press", r: 6, w: 135, inc: 5, key: 1)

    func testNoCapMeansNormalProgression() {
        XCTAssertEqual(engine().progressedWeight(goblet, 95), 100)
    }

    func testCapStopsDumbbellLiftsButNotBarbells() {
        var e = engine(); e.db.maxDb = 95
        XCTAssertEqual(e.progressedWeight(goblet, 90), 95)
        XCTAssertEqual(e.progressedWeight(goblet, 95), 95)
        XCTAssertTrue(e.atDbMax(goblet, 95))
        XCTAssertFalse(e.atDbMax(goblet, 90))
        XCTAssertEqual(e.progressedWeight(barbell, 135), 140)
        XCTAssertFalse(e.atDbMax(barbell, 400))
    }

    func testAlreadyAboveTheCapStaysPut() {
        var e = engine(); e.db.maxDb = 95
        XCTAssertEqual(e.progressedWeight(goblet, 100), 100)
    }

    func testStepperStartsAt95StepsByFiveAndClearsBelow20() {
        var e = engine()
        e.adjustMaxDb(5); XCTAssertEqual(e.db.maxDb, 95)
        e.adjustMaxDb(5); XCTAssertEqual(e.db.maxDb, 100)
        e.adjustMaxDb(-5); e.adjustMaxDb(-5); XCTAssertEqual(e.db.maxDb, 90)
        e.db.maxDb = 20; e.adjustMaxDb(-5); XCTAssertNil(e.db.maxDb)
    }

    func testSurvivesEncodeDecode() throws {
        var e = engine(); e.db.maxDb = 95
        let data = try JSONEncoder().encode(e.db)
        XCTAssertEqual(try JSONDecoder().decode(AppData.self, from: data).maxDb, 95)
    }
}
