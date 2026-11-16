import XCTest
@testable import VidFileBrowser

final class FinderTagsWriteTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FinderTagsTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    func testTagsRoundTrip() throws {
        let file = directory.appendingPathComponent("clip.mov")
        try Data().write(to: file)
        let tags = [
            FileTag(name: "Red", color: .red),
            FileTag(name: "Todo")
        ]

        try FinderTags.setTags(tags, for: file)

        let stored = try XCTUnwrap(FinderTags.tags(for: file))
        XCTAssertEqual(stored.count, 2)
        XCTAssertEqual(stored[0].name, "Red")
        XCTAssertEqual(stored[0].color, .red)
        XCTAssertEqual(stored[1].name, "Todo")
        XCTAssertNil(stored[1].color)
    }

    func testEmptyTagsAreRemoved() throws {
        let file = directory.appendingPathComponent("clip.mov")
        try Data().write(to: file)
        try FinderTags.setTags([FileTag(name: "Blue", color: .blue)], for: file)

        try FinderTags.setTags([], for: file)

        XCTAssertNil(FinderTags.tags(for: file))
    }

    func testStoredValueFormat() {
        XCTAssertEqual(FileTag(name: "Red", color: .red).storedValue, "Red\n6")
        XCTAssertEqual(FileTag(name: "Todo").storedValue, "Todo")
    }
}

final class FileMetadataTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileMetadataTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    func testCaptureAndApply() throws {
        let source = directory.appendingPathComponent("source.mov")
        let target = directory.appendingPathComponent("target.mov")
        try Data().write(to: source)

        let date = Date(timeIntervalSince1970: 1_000_000)
        try FinderTags.setTags([FileTag(name: "Green", color: .green)], for: source)
        try FileManager.default.setAttributes([.creationDate: date], ofItemAtPath: source.path)

        let metadata = FileMetadata.capture(at: source)
        try Data().write(to: target)
        metadata.apply(to: target)

        XCTAssertEqual(FinderTags.tags(for: target)?.first?.name, "Green")
        XCTAssertEqual(FinderTags.tags(for: target)?.first?.color, .green)
        let values = try target.resourceValues(forKeys: [.creationDateKey])
        XCTAssertEqual(try XCTUnwrap(values.creationDate).timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 1)
    }
}
