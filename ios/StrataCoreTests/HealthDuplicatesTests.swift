import XCTest
@testable import StrataCore

/// The Watch's own recording of a session must not show up next to the session Strata logged.
final class HealthDuplicatesTests: XCTestCase {
    private func engine(lifts: [String] = [], cardio: [CardioEntry] = []) -> Engine {
        let profile = Profile(name: "Nico", initials: "NI", gender: "male", plan: "nr", bw: 194, exp: "trained")
        var db = AppData.fresh()
        db.history = lifts.map { Session(date: $0, day: 4, vol: nil, entries: OrderedDict<Entry>(), lowEnergy: nil, min: 56, swaps: nil) }
        db.cardio = cardio
        let now = ISO8601DateFormatter().date(from: "2026-11-07T12:00:00Z")!.timeIntervalSince1970 * 1_000
        return Engine(profile: profile, db: db, nowMs: now, tz: TimeZone(secondsFromGMT: 0)!)
    }
    private let today = "2026-11-07"

    func testStrengthWorkoutOnADayYouLiftedIsTheSameSession() {
        let e = engine(lifts: [today])
        XCTAssertEqual(e.newExternalWorkouts([ExternalWorkout(isStrength: true, minutes: 64)], on: today), [])
    }

    func testStrengthWorkoutOnADayWithoutALiftStaysVisible() {
        let e = engine()
        XCTAssertEqual(e.newExternalWorkouts([ExternalWorkout(isStrength: true, minutes: 64)], on: today), [0])
    }

    func testOneLiftHidesOnlyOneStrengthWorkout() {
        let e = engine(lifts: [today])
        let list = [ExternalWorkout(isStrength: true, minutes: 64), ExternalWorkout(isStrength: true, minutes: 30)]
        XCTAssertEqual(e.newExternalWorkouts(list, on: today), [1])
    }

    func testCardioMatchesByLength() {
        let e = engine(cardio: [CardioEntry(date: today, type: "z2", min: 30)])
        let list = [ExternalWorkout(isStrength: false, minutes: 32), ExternalWorkout(isStrength: false, minutes: 60)]
        XCTAssertEqual(e.newExternalWorkouts(list, on: today), [1])
    }

    func testOfficeWalksAndJumpsDoNotHideAnything() {
        let e = engine(cardio: [CardioEntry(date: today, type: "office", steps: 9000), CardioEntry(date: today, type: "jumps")])
        XCTAssertEqual(e.newExternalWorkouts([ExternalWorkout(isStrength: false, minutes: 30)], on: today), [0])
    }
}
