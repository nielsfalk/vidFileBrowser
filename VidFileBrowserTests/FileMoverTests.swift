import XCTest
@testable import VidFileBrowser

final class FileMoverTests: XCTestCase {
    private var directory: URL!
    private var target: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileMoverTests-\(UUID().uuidString)", isDirectory: true)
        target = directory.appendingPathComponent("Target", isDirectory: true)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    func testMoveCopiesTheFileIntoTheFolder() throws {
        let file = directory.appendingPathComponent("clip.mov")
        try Data("data".utf8).write(to: file)

        try FileMover.move(file, into: target)

        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: target.appendingPathComponent("clip.mov").path))
    }

    func testExistingDestinationIsRejected() throws {
        let file = directory.appendingPathComponent("clip.mov")
        try Data("data".utf8).write(to: file)
        try Data("other".utf8).write(to: target.appendingPathComponent("clip.mov"))

        XCTAssertThrowsError(try FileMover.move(file, into: target)) { error in
            XCTAssertEqual(error as? MoveError, .destinationExists("clip.mov"))
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
    }

    func testMovingIntoSameFolderIsANoOp() throws {
        let file = directory.appendingPathComponent("clip.mov")
        try Data("data".utf8).write(to: file)

        try FileMover.move(file, into: directory)

        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
    }

    func testMissingFolderIsRejected() throws {
        let file = directory.appendingPathComponent("clip.mov")
        try Data("data".utf8).write(to: file)
        let missing = directory.appendingPathComponent("Missing", isDirectory: true)

        XCTAssertThrowsError(try FileMover.move(file, into: missing)) { error in
            XCTAssertEqual(error as? MoveError, .notADirectory("Missing"))
        }
    }
}
