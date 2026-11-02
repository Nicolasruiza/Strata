import XCTest
@testable import StrataCore

final class WatchMessageTests: XCTestCase {
    func testRoundTrip() {
        for m in [WatchMessage.hr(142.5), .cue, .end, .ended(saved: true), .ended(saved: false)] {
            XCTAssertEqual(WatchMessage.decode(m.encoded()!), m)
        }
    }
    func testGarbageDecodesToNil() {
        XCTAssertNil(WatchMessage.decode(Data("nope".utf8)))
    }
}
