import XCTest
@testable import VidFileBrowser

final class FavoritesStoreTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!
    private var directory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        suiteName = "FavoritesStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FavoritesStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testAddPersistsAndResolves() throws {
        let store = FavoritesStore(defaults: defaults)
        try store.add(directory)

        let reloaded = FavoritesStore(defaults: defaults)
        XCTAssertEqual(reloaded.folders.count, 1)
        XCTAssertEqual(reloaded.folders.first?.name, directory.lastPathComponent)

        let resolved = try XCTUnwrap(reloaded.url(for: try XCTUnwrap(reloaded.folders.first)))
        XCTAssertEqual(resolved.standardizedFileURL.path, directory.standardizedFileURL.path)
    }

    func testRemovedFavoritesAreGone() throws {
        let store = FavoritesStore(defaults: defaults)
        try store.add(directory)

        store.remove(atOffsets: [0])

        XCTAssertTrue(store.folders.isEmpty)
        XCTAssertTrue(FavoritesStore(defaults: defaults).folders.isEmpty)
    }

    func testMoveReordersFavorites() throws {
        let other = directory.appendingPathComponent("Other", isDirectory: true)
        try FileManager.default.createDirectory(at: other, withIntermediateDirectories: true)

        let store = FavoritesStore(defaults: defaults)
        try store.add(directory)
        try store.add(other)

        store.move(fromOffsets: [1], toOffset: 0)

        XCTAssertEqual(store.folders.map(\.name), [other.lastPathComponent, directory.lastPathComponent])
        XCTAssertEqual(FavoritesStore(defaults: defaults).folders.map(\.name), [other.lastPathComponent, directory.lastPathComponent])
    }

    func testBookmarkSurvivesRename() throws {
        let store = FavoritesStore(defaults: defaults)
        try store.add(directory)

        let renamed = directory.deletingLastPathComponent()
            .appendingPathComponent("Renamed-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.moveItem(at: directory, to: renamed)
        defer { try? FileManager.default.removeItem(at: renamed) }

        let folder = try XCTUnwrap(store.folders.first)
        let resolved = try XCTUnwrap(store.url(for: folder))
        XCTAssertEqual(resolved.standardizedFileURL.path, renamed.standardizedFileURL.path)
    }

    func testMissingFolderDoesNotResolve() throws {
        let store = FavoritesStore(defaults: defaults)
        try store.add(directory)
        try FileManager.default.removeItem(at: directory)

        XCTAssertNil(store.url(for: try XCTUnwrap(store.folders.first)))
    }
}
