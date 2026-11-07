import XCTest
@testable import StrataCore

final class SledTests: XCTestCase {
    func testLegPressShowsWhatToLoadOnEachSide() {
        XCTAssertEqual(Fmt.sledTxt(180), "45 + 45 / side (plates only)")
        XCTAssertEqual(Fmt.sledTxt(90), "45 / side (plates only)")
        XCTAssertEqual(Fmt.sledTxt(210), "45 + 45 + 10 + 5 / side (plates only)")
        XCTAssertEqual(Fmt.sledTxt(0), "Empty sled")
    }
}
