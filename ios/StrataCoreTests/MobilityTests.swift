import XCTest
@testable import StrataCore

final class MobilityTests: XCTestCase {
    private func engine() -> Engine {
        let profile = Profile(name: "Nico", initials: "NI", gender: "male", plan: "nr", bw: 194, exp: "trained")
        let now = ISO8601DateFormatter().date(from: "2026-11-04T12:00:00Z")!.timeIntervalSince1970 * 1_000
        return Engine(profile: profile, db: AppData.fresh(), nowMs: now, tz: TimeZone(secondsFromGMT: 0)!)
    }

    func testToggleChecksAndUndoes() {
        var e = engine()
        XCTAssertTrue(e.toggleMobility(session: "morning", ex: "glide"))
        XCTAssertEqual(e.mobilityCount(date: e.today, session: "morning"), 1)
        XCTAssertFalse(e.toggleMobility(session: "morning", ex: "glide"))
        XCTAssertEqual(e.mobilityCount(date: e.today, session: "morning"), 0)
        XCTAssertNil(e.db.mobility)
    }

    func testMorningAndEveningAreSeparate() {
        var e = engine()
        for ex in Config.Mobility.exercises { e.toggleMobility(session: "evening", ex: ex.id) }
        XCTAssertTrue(e.mobilitySessionComplete(date: e.today, session: "evening"))
        XCTAssertFalse(e.mobilitySessionComplete(date: e.today, session: "morning"))
        XCTAssertEqual(e.mobilitySessionsDone(date: e.today), 1)
        XCTAssertEqual(e.mobilityDays(in: [e.today, Dates.addDays(e.today, -1)]), 1)
    }

    func testSetsAreTrackedOneByOne() {
        var e = engine()   // glide is 4 sets
        for i in 0..<3 { e.tapMobilitySet(session: "morning", ex: "glide", index: i) }
        XCTAssertEqual(e.mobilitySets(date: e.today, session: "morning", ex: "glide"), 3)
        XCTAssertEqual(e.mobilityCount(date: e.today, session: "morning"), 0)   // not done until the last set
        e.tapMobilitySet(session: "morning", ex: "glide", index: 3)
        XCTAssertEqual(e.mobilityCount(date: e.today, session: "morning"), 1)
        e.tapMobilitySet(session: "morning", ex: "glide", index: 3)             // tapping the last again steps back
        XCTAssertEqual(e.mobilitySets(date: e.today, session: "morning", ex: "glide"), 3)
    }

    func testOlderEntriesWithoutSetsCountAsDone() {
        var e = engine()
        e.db.mobility = [MobilityDone(date: e.today, session: "morning", ex: "glide")]
        XCTAssertEqual(e.mobilityCount(date: e.today, session: "morning"), 1)
    }

    func testSetsAreClamped() {
        var e = engine()
        e.setMobilitySets(session: "evening", ex: "itband", sets: 9)   // itband is 1 set
        XCTAssertEqual(e.mobilitySets(date: e.today, session: "evening", ex: "itband"), 1)
    }

    func testPartialSessionDoesNotCountAsADay() {
        var e = engine()
        e.toggleMobility(session: "morning", ex: "pressup")
        XCTAssertEqual(e.mobilityDays(in: [e.today]), 0)
    }

    func testUnknownIdsAreIgnored() {
        var e = engine()
        XCTAssertFalse(e.toggleMobility(session: "noon", ex: "glide"))
        XCTAssertFalse(e.toggleMobility(session: "morning", ex: "nope"))
        XCTAssertNil(e.db.mobility)
    }

    func testDoesNotTouchRingsOrInsights() {
        var e = engine()
        let before = e.weekStats(Dates.mondayOf(e.today))
        for s in Config.Mobility.sessions { for ex in Config.Mobility.exercises { e.toggleMobility(session: s.id, ex: ex.id) } }
        XCTAssertEqual(e.weekStats(Dates.mondayOf(e.today)).closed, before.closed)
        XCTAssertEqual(e.insights(health: HealthSignals()).map(\.kind), [.remaining])
    }

    func testStoredDataRoundTrips() throws {
        var e = engine()
        e.toggleMobility(session: "morning", ex: "itband")
        let back = try JSONDecoder().decode(AppData.self, from: JSONEncoder().encode(e.db))
        XCTAssertEqual(back.mobility, e.db.mobility)
    }
}
