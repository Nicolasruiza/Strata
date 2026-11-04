import XCTest
@testable import StrataCore

final class WatchMessageTests: XCTestCase {
    func testRoundTrip() {
        let exercise = WatchExerciseSnapshot(id: "bench", name: "Bench Press", imageName: "bench_press", setIndex: 2,
                                             setCount: 4, targetReps: 10, load: 190, loadUnit: "lb",
                                             loadIncrement: 5, lastSummary: "10 · 10 · 9 at 185",
                                             durationSeconds: nil, restSeconds: 180)
        let state = WatchStateSnapshot(revision: 2, mode: .strength, exercise: exercise)
        let done = WatchSetDone(exerciseID: "bench", setIndex: 2, actualReps: 9, actualLoad: 190)
        let messages: [WatchMessage] = [.hr(142.5), .cue, .end, .ended(saved: true), .ended(saved: false),
                                        .requestState, .startWorkout(UUID()), .state(state), .setDone(done), .skipRest(UUID())]
        for m in messages {
            XCTAssertEqual(WatchMessage.decode(m.encoded()!), m)
        }
    }
    func testGarbageDecodesToNil() {
        XCTAssertNil(WatchMessage.decode(Data("nope".utf8)))
    }
}
