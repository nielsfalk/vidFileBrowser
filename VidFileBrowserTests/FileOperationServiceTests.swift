import XCTest
@testable import VidFileBrowser

final class FileOperationServiceTests: XCTestCase {
    private var directory: URL!
    private var target: URL!
    private let service = FileOperationService()

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileOperationServiceTests-\(UUID().uuidString)", isDirectory: true)
        target = directory.appendingPathComponent("Target", isDirectory: true)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    func testCopyCopiesTheFile() throws {
        let source = try makeFile("clip.mov", contents: "data")

        try service.perform(.copy, sources: [source], into: target) { _ in .skip }

        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertEqual(
            try String(contentsOf: target.appendingPathComponent("clip.mov"), encoding: .utf8),
            "data"
        )
    }

    func testMoveRemovesTheSource() throws {
        let source = try makeFile("clip.mov", contents: "data")

        try service.perform(.move, sources: [source], into: target) { _ in .skip }

        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: target.appendingPathComponent("clip.mov").path))
    }

    func testKeepBothUsesAUniqueName() throws {
        let source = try makeFile("clip.mov", contents: "new")
        try Data("old".utf8).write(to: target.appendingPathComponent("clip.mov"))

        try service.perform(.copy, sources: [source], into: target) { _ in .keepBoth }

        XCTAssertEqual(
            try String(contentsOf: target.appendingPathComponent("clip 2.mov"), encoding: .utf8),
            "new"
        )
    }

    func testReplaceOverwritesTheDestination() throws {
        let source = try makeFile("clip.mov", contents: "new")
        try Data("old".utf8).write(to: target.appendingPathComponent("clip.mov"))

        try service.perform(.copy, sources: [source], into: target) { _ in .replace }

        XCTAssertEqual(
            try String(contentsOf: target.appendingPathComponent("clip.mov"), encoding: .utf8),
            "new"
        )
    }

    func testSkipLeavesTheDestination() throws {
        let source = try makeFile("clip.mov", contents: "new")
        try Data("old".utf8).write(to: target.appendingPathComponent("clip.mov"))

        try service.perform(.copy, sources: [source], into: target) { _ in .skip }

        XCTAssertEqual(
            try String(contentsOf: target.appendingPathComponent("clip.mov"), encoding: .utf8),
            "old"
        )
    }

    func testCancelStopsTheWholeOperation() throws {
        let first = try makeFile("a.mov", contents: "a")
        let second = try makeFile("b.mov", contents: "b")
        try Data("old".utf8).write(to: target.appendingPathComponent("b.mov"))

        XCTAssertThrowsError(
            try service.perform(.copy, sources: [first, second], into: target) { _ in .cancel }
        ) { error in
            XCTAssertTrue(error is CancellationError)
        }
        // Files before the cancelled conflict are already copied; the rest is left alone.
        XCTAssertTrue(FileManager.default.fileExists(atPath: target.appendingPathComponent("a.mov").path))
        XCTAssertEqual(
            try String(contentsOf: target.appendingPathComponent("b.mov"), encoding: .utf8),
            "old"
        )
    }

    func testUniqueDestinationKeepsTheExtension() {
        let url = target.appendingPathComponent("clip.mov")
        try? Data().write(to: url)

        let unique = FileOperationService.uniqueDestination(for: url)

        XCTAssertEqual(unique.lastPathComponent, "clip 2.mov")
    }

    private func makeFile(_ name: String, contents: String) throws -> URL {
        let url = directory.appendingPathComponent(name)
        try Data(contents.utf8).write(to: url)
        return url
    }
}
