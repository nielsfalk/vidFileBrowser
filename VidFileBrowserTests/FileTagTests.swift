import XCTest
@testable import VidFileBrowser

final class FileTagTests: XCTestCase {
    func testParsesColorTag() {
        let tag = FileTag(rawValue: "Red\n6")

        XCTAssertEqual(tag.name, "Red")
        XCTAssertEqual(tag.color, .red)
    }

    func testParsesTagWithoutColor() {
        let tag = FileTag(rawValue: "Project X")

        XCTAssertEqual(tag.name, "Project X")
        XCTAssertNil(tag.color)
    }

    func testParsesTrailingFieldsFromNewerMacOS() {
        let tag = FileTag(rawValue: "Red\n6\n0")

        XCTAssertEqual(tag.name, "Red")
        XCTAssertEqual(tag.color, .red)
    }

    func testUnknownColorHasNoColor() {
        let tag = FileTag(rawValue: "Custom\n99")

        XCTAssertEqual(tag.name, "Custom")
        XCTAssertNil(tag.color)
    }
}
