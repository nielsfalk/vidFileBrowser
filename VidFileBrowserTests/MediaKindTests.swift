import XCTest
import UniformTypeIdentifiers
@testable import VidFileBrowser

final class MediaKindTests: XCTestCase {
    func testDetectsVideoByExtension() {
        XCTAssertEqual(MediaKindDetector.kind(for: URL(fileURLWithPath: "/tmp/clip.mkv")), .video)
        XCTAssertEqual(MediaKindDetector.kind(for: URL(fileURLWithPath: "/tmp/clip.MP4")), .video)
        XCTAssertEqual(MediaKindDetector.kind(for: URL(fileURLWithPath: "/tmp/clip.webm")), .video)
    }

    func testDetectsImageByExtension() {
        XCTAssertEqual(MediaKindDetector.kind(for: URL(fileURLWithPath: "/tmp/photo.heic")), .image)
        XCTAssertEqual(MediaKindDetector.kind(for: URL(fileURLWithPath: "/tmp/photo.jpg")), .image)
    }

    func testDetectsOtherFiles() {
        XCTAssertEqual(MediaKindDetector.kind(for: URL(fileURLWithPath: "/tmp/notes.txt")), .other)
        XCTAssertFalse(MediaKind.other.isPlayable)
    }

    func testPrefersContentType() {
        let kind = MediaKindDetector.kind(
            for: URL(fileURLWithPath: "/tmp/movie"),
            contentType: .movie
        )

        XCTAssertEqual(kind, .video)
    }
}
