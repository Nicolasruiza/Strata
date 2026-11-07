import XCTest
@testable import StrataCore

final class SessionSummaryTests: XCTestCase {
    private func make(_ day: Int = 0, entries: [(String, Entry)] = [], low: Bool = false) -> Engine {
        let profile = Profile(name: "Nico", initials: "NI", gender: "male", plan: "nr", bw: 194, exp: "trained")
        var data = AppData.fresh()
        var map = OrderedDict<Entry>()
        for (id, en) in entries { map[id] = en }
        data.history = [Session(date: "2026-11-05", day: day, vol: 0, entries: map, lowEnergy: low, min: 60, swaps: nil)]
        let now = ISO8601DateFormatter().date(from: "2026-11-06T12:00:00Z")!.timeIntervalSince1970 * 1_000
        return Engine(profile: profile, db: data, nowMs: now, tz: TimeZone(secondsFromGMT: 0)!)
    }

    /// Two lifts of the first plan day that can progress.
    private func lifts() throws -> (day: Int, a: Ex, b: Ex) {
        let probe = make()
        let day = try XCTUnwrap(probe.plan.keys.sorted().first)
        let ex = (probe.plan[day]?.blocks ?? []).flatMap(\.items).filter { ($0.inc ?? 0) != 0 && ($0.r ?? 0) != 0 }
        XCTAssertGreaterThanOrEqual(ex.count, 2)
        return (day, ex[0], ex[1])
    }

    func testPastSessionShowsWhatWentUpAndWhatHeld() throws {
        let (day, a, b) = try lifts()
        let e = make(day, entries: [(a.id, Entry(w: 50, reps: Array(repeating: Double(a.r!), count: 3))),
                                    (b.id, Entry(w: 40, reps: Array(repeating: Double(b.r!) - 2, count: 3)))])
        let c = try XCTUnwrap(e.celebration(forSession: 0))
        XCTAssertEqual(c.ups, [a.id])
        XCTAssertEqual(c.holds, [b.id])
        let rows = try XCTUnwrap(e.sessionSummary(c, derivedNext: true)).rows
        XCTAssertEqual(rows.first { $0.id == a.id }?.up, true)
        XCTAssertEqual(rows.first { $0.id == a.id }?.next, e.progressedWeight(a, 50))   // not today's db.next
        XCTAssertEqual(rows.first { $0.id == b.id }?.next, 40)
    }

    func testLighterDayNeverProgresses() throws {
        let (day, a, _) = try lifts()
        let e = make(day, entries: [(a.id, Entry(w: 50, reps: [Double(a.r!)]))], low: true)
        XCTAssertEqual(e.celebration(forSession: 0)?.ups, [])
    }

    func testUnknownSessionIsNil() {
        XCTAssertNil(make().celebration(forSession: 5))
    }
}
