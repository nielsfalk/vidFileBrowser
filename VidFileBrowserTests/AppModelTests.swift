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
        let model = AppModel(settings: AppSettings(defaults: defaults), restoreLastFolder: false)

        model.open(directory)

        XCTAssertEqual(model.directory?.path, directory.path)
        XCTAssertEqual(AppSettings(defaults: defaults).lastFolderPath, directory.path)
    }

    func testLastFolderIsRestored() {
        let settings = AppSettings(defaults: defaults)
        settings.lastFolderPath = directory.path

        let model = AppModel(settings: settings)

        XCTAssertEqual(model.directory?.path, directory.path)
    }

    func testMissingLastFolderIsIgnored() {
        let settings = AppSettings(defaults: defaults)
        settings.lastFolderPath = directory.appendingPathComponent("missing").path

        let model = AppModel(settings: settings)

        XCTAssertNil(model.directory)
        XCTAssertTrue(model.items.isEmpty)
    }

    func testListsFolderContentsInSortOrder() throws {
        try FileManager.default.createDirectory(
            at: directory.appendingPathComponent("Sub", isDirectory: true),
            withIntermediateDirectories: true
        )
        try Data().write(to: directory.appendingPathComponent("b.mov"))
        try Data().write(to: directory.appendingPathComponent("a.mkv"))

        let model = AppModel(settings: AppSettings(defaults: defaults), restoreLastFolder: false)
        model.sortProperty = .name
        model.sortAscending = true
        model.open(directory)

        XCTAssertEqual(model.items.map(\.name), ["Sub", "a.mkv", "b.mov"])
    }
}
