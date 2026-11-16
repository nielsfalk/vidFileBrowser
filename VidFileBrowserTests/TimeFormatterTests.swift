import XCTest
@testable import VidFileBrowser

final class TimeFormatterTests: XCTestCase {
    func testMinutesAndSeconds() {
        XCTAssertEqual(TimeFormatter.string(from: 0), "0:00")
        XCTAssertEqual(TimeFormatter.string(from: 5), "0:05")
        XCTAssertEqual(TimeFormatter.string(from: 65), "1:05")
        XCTAssertEqual(TimeFormatter.string(from: 3599), "59:59")
    }

    func testHours() {
        XCTAssertEqual(TimeFormatter.string(from: 3600), "1:00:00")
        XCTAssertEqual(TimeFormatter.string(from: 3725), "1:02:05")
    }

    func testInvalidValues() {
        XCTAssertEqual(TimeFormatter.string(from: -3), "0:00")
        XCTAssertEqual(TimeFormatter.string(from: .infinity), "0:00")
        XCTAssertEqual(TimeFormatter.string(from: .nan), "0:00")
    }
}
