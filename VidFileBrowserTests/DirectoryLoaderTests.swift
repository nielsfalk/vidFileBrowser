import XCTest
@testable import VidFileBrowser

final class DirectoryLoaderTests: XCTestCase {
    private var root: URL!
    private let fileManager = FileManager.default

    override func setUpWithError() throws {
        root = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? fileManager.removeItem(at: root)
    }

    func testLoadsFilesAndFolders() throws {
        try fileManager.createDirectory(at: root.appendingPathComponent("Folder"), withIntermediateDirectories: true)
        try Data("hello".utf8).write(to: root.appendingPathComponent("notes.txt"))
        try Data("video".utf8).write(to: root.appendingPathComponent("clip.mp4"))

        let items = try DirectoryLoader().loadItems(in: root)
        let byName = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0) })

        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(byName["Folder"]?.isDirectory, true)
        XCTAssertEqual(byName["Folder"]?.kind, .other)
        XCTAssertEqual(byName["notes.txt"]?.kind, .other)
        XCTAssertEqual(byName["notes.txt"]?.size, 5)
        XCTAssertEqual(byName["clip.mp4"]?.kind, .video)
        XCTAssertNotNil(byName["clip.mp4"]?.modificationDate)
    }

    func testLoadsFinderTags() throws {
        // Writing tag resource values needs macOS 26; the app itself targets 14.
        guard #available(macOS 26.0, *) else {
            throw XCTSkip("Setting Finder tags needs macOS 26 or newer")
        }

        let file = root.appendingPathComponent("tagged.mov")
        try Data().write(to: file)
        var values = URLResourceValues()
        values.tagNames = ["Red\n6", "Project"]
        var mutableURL = file
        try mutableURL.setResourceValues(values)

        let items = try DirectoryLoader().loadItems(in: root)
        let tags = try XCTUnwrap(items.first?.tags)

        XCTAssertEqual(tags.map(\.name), ["Red", "Project"])
        XCTAssertEqual(tags.map(\.color), [.red, nil])
    }

    func testLoadsEmptyDirectory() throws {
        XCTAssertEqual(try DirectoryLoader().loadItems(in: root), [])
    }
}
