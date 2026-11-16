import XCTest
@testable import VidFileBrowser

final class TrimNamingTests: XCTestCase {
    func testAddsSuffixBeforeTheFirstDot() {
        XCTAssertEqual(TrimNaming.trimmedName(for: "clip.mov"), "clip_t.mov")
    }

    func testKeepsExistingSuffix() {
        XCTAssertEqual(TrimNaming.trimmedName(for: "clip_t.mov"), "clip_t.mov")
        XCTAssertEqual(TrimNaming.trimmedName(for: "clip_t"), "clip_t")
    }

    func testUsesTheFirstDot() {
        XCTAssertEqual(TrimNaming.trimmedName(for: "archive.tar.gz"), "archive_t.tar.gz")
    }

    func testFileNameWithoutExtension() {
        XCTAssertEqual(TrimNaming.trimmedName(for: "clip"), "clip_t")
    }

    func testSuffixInTheMiddleIsNotEnough() {
        XCTAssertEqual(TrimNaming.trimmedName(for: "clip_take.mov"), "clip_take_t.mov")
    }

    func testHiddenFile() {
        XCTAssertEqual(TrimNaming.trimmedName(for: ".clip.mov"), ".clip_t.mov")
    }

    func testEmptyName() {
        XCTAssertEqual(TrimNaming.trimmedName(for: ""), "")
    }
}
