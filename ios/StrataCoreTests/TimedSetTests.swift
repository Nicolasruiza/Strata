import XCTest
@testable import StrataCore

/// The timer hands the held seconds to the set log through `woReps`: a full hold logs the target, Stop logs less.
final class TimedSetTests: XCTestCase {
    private func engine() -> Engine {
        let profile = Profile(name: "Nico", initials: "NI", gender: "male", plan: "nr", bw: 194, exp: "trained")
        let now = ISO8601DateFormatter().date(from: "2026-11-07T12:00:00Z")!.timeIntervalSince1970 * 1_000
        return Engine(profile: profile, db: AppData.fresh(), nowMs: now, tz: TimeZone(secondsFromGMT: 0)!)
    }

    func testHeldSecondsAreLoggedAsTheSet() {
        var e = engine(); e.begin(day: 4)
        guard let i = e.liftList().firstIndex(where: { $0.id == "farmer" }) else { return XCTFail("no farmer carry on day 4") }
        _ = e.openEx(i)
        XCTAssertTrue(Fmt.isSec(e.shownEx(e.liftList()[e.curIdx()])))
        e.woReps = 45; _ = e.logWoSet()
        e.woReps = 31; _ = e.logWoSet()
        XCTAssertEqual(e.db.active?.prog["farmer"]?.reps.compactMap { $0 }, [45, 31])
        XCTAssertNil(e.woReps)
    }
}
