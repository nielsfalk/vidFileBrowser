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
