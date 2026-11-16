import XCTest
@testable import VidFileBrowser

final class AppModelTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!
    private var directory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        suiteName = "AppModelTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppModelTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testOpeningAFolderStoresItAsLastFolder() {
        let model = AppModel(settings: AppSettings(defaults: defaults), player: PlayerController(), restoreLastFolder: false)

        model.open(directory)

        XCTAssertEqual(model.directory?.path, directory.path)
        XCTAssertEqual(AppSettings(defaults: defaults).lastFolderPath, directory.path)
    }

    func testLastFolderIsRestored() {
        let settings = AppSettings(defaults: defaults)
        settings.lastFolderPath = directory.path

        let model = AppModel(settings: settings, player: PlayerController())

        XCTAssertEqual(model.directory?.path, directory.path)
    }

    func testMissingLastFolderIsIgnored() {
        let settings = AppSettings(defaults: defaults)
        settings.lastFolderPath = directory.appendingPathComponent("missing").path

        let model = AppModel(settings: settings, player: PlayerController())

        XCTAssertNil(model.directory)
        XCTAssertTrue(model.items.isEmpty)
    }

    func testSelectingAVideoStartsPlayback() throws {
        let videoURL = directory.appendingPathComponent("clip.mov")
        try Data().write(to: videoURL)

        let player = PlayerController()
        let model = AppModel(settings: AppSettings(defaults: defaults), player: player, restoreLastFolder: false)
        model.open(directory)
        let item = try XCTUnwrap(model.items.first)
        model.selection = [item.id]

        model.selectionDidChange()

        XCTAssertEqual(player.currentURL, item.url)
    }

    func testSelectingAnImageShowsIt() throws {
        let imageURL = directory.appendingPathComponent("photo.png")
        try TestImage.pngData(width: 4, height: 4).write(to: imageURL)

        let player = PlayerController()
        let model = AppModel(settings: AppSettings(defaults: defaults), player: player, restoreLastFolder: false)
        model.open(directory)
        let item = try XCTUnwrap(model.items.first { $0.name == "photo.png" })
        model.selection = [item.id]

        model.selectionDidChange()

        XCTAssertNotNil(model.image)
        XCTAssertEqual(model.imageURL, item.url)
        XCTAssertNil(player.currentURL)
    }

    func testSelectingANonPlayableFileStopsPlayback() throws {
        let textURL = directory.appendingPathComponent("notes.txt")
        try Data().write(to: textURL)

        let player = PlayerController()
        let model = AppModel(settings: AppSettings(defaults: defaults), player: player, restoreLastFolder: false)
        model.open(directory)
        let item = try XCTUnwrap(model.items.first)
        model.selection = [item.id]

        model.selectionDidChange()

        XCTAssertNil(player.currentURL)
    }

    func testToggleTagUpdatesTheList() throws {
        try Data().write(to: directory.appendingPathComponent("clip.mov"))
        let model = AppModel(settings: AppSettings(defaults: defaults), player: PlayerController(), restoreLastFolder: false)
        model.open(directory)
        let item = try XCTUnwrap(model.items.first)

        model.toggleTag(.red, on: item)

        XCTAssertEqual(model.items.first?.tagColors, [.red])

        model.removeAllTags(from: try XCTUnwrap(model.items.first))
        XCTAssertEqual(model.items.first?.tags, [])
    }

    func testMoveToFolderUpdatesTheList() throws {
        try Data().write(to: directory.appendingPathComponent("clip.mov"))
        let target = directory.appendingPathComponent("Target", isDirectory: true)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)

        let model = AppModel(settings: AppSettings(defaults: defaults), player: PlayerController(), restoreLastFolder: false)
        model.open(directory)
        let item = try XCTUnwrap(model.items.first { $0.name == "clip.mov" })

        XCTAssertTrue(model.move(item, to: target))

        XCTAssertNil(model.errorMessage)
        XCTAssertTrue(FileManager.default.fileExists(atPath: target.appendingPathComponent("clip.mov").path))
        XCTAssertFalse(model.items.contains { $0.name == "clip.mov" })
    }

    func testMoveConflictShowsAnError() throws {
        try Data().write(to: directory.appendingPathComponent("clip.mov"))
        let target = directory.appendingPathComponent("Target", isDirectory: true)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        try Data().write(to: target.appendingPathComponent("clip.mov"))

        let model = AppModel(settings: AppSettings(defaults: defaults), player: PlayerController(), restoreLastFolder: false)
        model.open(directory)
        let item = try XCTUnwrap(model.items.first { $0.name == "clip.mov" })

        XCTAssertFalse(model.move(item, to: target))

        XCTAssertNotNil(model.errorMessage)
        XCTAssertTrue(model.items.contains { $0.name == "clip.mov" })
    }

    func testRenameMovesTheFileAndSelectsIt() throws {
        try Data().write(to: directory.appendingPathComponent("old.mov"))
        let model = AppModel(settings: AppSettings(defaults: defaults), player: PlayerController(), restoreLastFolder: false)
        model.open(directory)
        let item = try XCTUnwrap(model.items.first)

        XCTAssertTrue(model.rename(item, to: "new.mov"))

        XCTAssertEqual(model.items.map(\.name), ["new.mov"])
        XCTAssertEqual(model.selection, [model.items[0].id])
        XCTAssertFalse(FileManager.default.fileExists(atPath: item.url.path))
    }

    func testRenameRejectsExistingNames() throws {
        try Data().write(to: directory.appendingPathComponent("a.mov"))
        try Data().write(to: directory.appendingPathComponent("b.mov"))
        let model = AppModel(settings: AppSettings(defaults: defaults), player: PlayerController(), restoreLastFolder: false)
        model.open(directory)
        let item = try XCTUnwrap(model.items.first { $0.name == "a.mov" })

        XCTAssertFalse(model.rename(item, to: "b.mov"))
        XCTAssertNotNil(model.errorMessage)
    }

    func testRenameRejectsInvalidNames() throws {
        try Data().write(to: directory.appendingPathComponent("a.mov"))
        let model = AppModel(settings: AppSettings(defaults: defaults), player: PlayerController(), restoreLastFolder: false)
        model.open(directory)
        let item = try XCTUnwrap(model.items.first)

        XCTAssertFalse(model.rename(item, to: "   "))
        XCTAssertFalse(model.rename(item, to: "a/b.mov"))
    }

    func testCopyPathsWritesToThePasteboard() throws {
        try Data().write(to: directory.appendingPathComponent("a.mov"))
        try Data().write(to: directory.appendingPathComponent("b.mov"))

        let pasteboard = NSPasteboard(name: NSPasteboard.Name("AppModelTests-\(UUID().uuidString)"))
        let model = AppModel(
            settings: AppSettings(defaults: defaults),
            player: PlayerController(),
            pasteboard: pasteboard,
            restoreLastFolder: false
        )
        model.open(directory)

        model.copyPaths(of: model.items)

        XCTAssertEqual(pasteboard.string(forType: .string), model.items.map(\.url.path).joined(separator: "\n"))
    }

    func testMoveToTrashRemovesTheFile() throws {
        try Data().write(to: directory.appendingPathComponent("a.mov"))

        let model = AppModel(
            settings: AppSettings(defaults: defaults),
            player: PlayerController(),
            trash: TestTrash(),
            restoreLastFolder: false
        )
        model.open(directory)
        let item = try XCTUnwrap(model.items.first)

        model.moveToTrash([item])

        XCTAssertTrue(model.items.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: item.url.path))
    }

    func testTrashingSelectsAndPlaysTheNextFile() throws {
        try Data().write(to: directory.appendingPathComponent("a.mov"))
        try Data().write(to: directory.appendingPathComponent("b.mov"))

        let player = PlayerController()
        let model = AppModel(
            settings: AppSettings(defaults: defaults),
            player: player,
            trash: TestTrash(),
            restoreLastFolder: false
        )
        model.open(directory)
        let first = try XCTUnwrap(model.items.first { $0.name == "a.mov" })
        model.selection = [first.id]
        model.selectionDidChange()

        model.moveToTrash([first])

        XCTAssertEqual(model.items.map(\.name), ["b.mov"])
        XCTAssertEqual(model.items.first.map { model.selection.contains($0.id) }, true)
        XCTAssertEqual(player.currentURL, model.items.first?.url)
    }

    func testListsFolderContentsInSortOrder() throws {
        try FileManager.default.createDirectory(
            at: directory.appendingPathComponent("Sub", isDirectory: true),
            withIntermediateDirectories: true
        )
        try Data().write(to: directory.appendingPathComponent("b.mov"))
        try Data().write(to: directory.appendingPathComponent("a.mkv"))

        let model = AppModel(settings: AppSettings(defaults: defaults), player: PlayerController(), restoreLastFolder: false)
        model.sortProperty = .name
        model.sortAscending = true
        model.open(directory)

        XCTAssertEqual(model.items.map(\.name), ["Sub", "a.mkv", "b.mov"])
    }
}

private struct TestTrash: FileTrashing {
    func trash(_ url: URL) throws -> URL? {
        try FileManager.default.removeItem(at: url)
        return nil
    }
}
