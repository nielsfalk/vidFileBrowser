import XCTest
@testable import VidFileBrowser

final class BreadcrumbBuilderTests: XCTestCase {
    func testNoFolderGivesNoSegments() {
        XCTAssertTrue(BreadcrumbBuilder.segments(for: nil).isEmpty)
    }

    func testSegmentsFollowThePath() {
        let url = URL(fileURLWithPath: "/tmp/video/clips", isDirectory: true)

        let segments = BreadcrumbBuilder.segments(for: url)

        XCTAssertEqual(segments.count, 4)
        XCTAssertEqual(segments.map(\.title).dropFirst(), ["tmp", "video", "clips"])
        XCTAssertEqual(segments.first?.url.path, "/")
        XCTAssertEqual(segments.last?.url, url)
    }

    func testRootGivesSingleSegment() {
        let segments = BreadcrumbBuilder.segments(for: URL(fileURLWithPath: "/"))

        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments.first?.url.path, "/")
        XCTAssertFalse(segments.first?.title.isEmpty ?? true)
    }

    func testHomeFolderIsCollapsed() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let url = home.appendingPathComponent("Movies", isDirectory: true)

        let segments = BreadcrumbBuilder.segments(for: url)

        XCTAssertEqual(segments.last?.title, "Movies")
        XCTAssertEqual(segments.last?.url, url)
        XCTAssertTrue(segments.contains { $0.title == "~" && $0.url == home })
    }
}
