import XCTest
@testable import VidFileBrowser

final class AppSettingsTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "AppSettingsTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testDefaultsWhenEmpty() {
        let settings = AppSettings(defaults: defaults)

        XCTAssertEqual(settings.sortProperty, .date)
        XCTAssertTrue(settings.sortAscending)
    }

    func testSortSettingsArePersisted() {
        let settings = AppSettings(defaults: defaults)
        settings.sortProperty = .size
        settings.sortAscending = false

        let reloaded = AppSettings(defaults: defaults)

        XCTAssertEqual(reloaded.sortProperty, .size)
        XCTAssertFalse(reloaded.sortAscending)
    }

    func testOldLabelSortSettingIsReadAsTags() {
        defaults.set("label", forKey: AppSettings.Key.sortProperty)

        XCTAssertEqual(AppSettings(defaults: defaults).sortProperty, .tag)
    }

    func testLayoutSettingsArePersisted() {
        let settings = AppSettings(defaults: defaults)
        XCTAssertEqual(settings.browserWidth, AppSettings.defaultBrowserWidth)
        XCTAssertNil(settings.lastFolderPath)

        settings.browserWidth = 512
        settings.lastFolderPath = "/tmp"

        let reloaded = AppSettings(defaults: defaults)
        XCTAssertEqual(reloaded.browserWidth, 512)
        XCTAssertEqual(reloaded.lastFolderPath, "/tmp")
    }

    func testLastViewedFileIsPersisted() {
        let settings = AppSettings(defaults: defaults)
        XCTAssertNil(settings.lastViewedFilePath)

        settings.lastViewedFilePath = "/tmp/clip.mov"

        XCTAssertEqual(AppSettings(defaults: defaults).lastViewedFilePath, "/tmp/clip.mov")
    }

    func testAutoTagSettingsArePersisted() {
        let settings = AppSettings(defaults: defaults)
        XCTAssertFalse(settings.autoTagEnabled)
        XCTAssertEqual(settings.autoTagColor, .green)

        settings.autoTagEnabled = true
        settings.autoTagColor = .red

        let reloaded = AppSettings(defaults: defaults)
        XCTAssertTrue(reloaded.autoTagEnabled)
        XCTAssertEqual(reloaded.autoTagColor, .red)
    }

    func testModelReadsAndWritesSortSettings() {
        let settings = AppSettings(defaults: defaults)
        settings.sortProperty = .tag
        settings.sortAscending = false

        let model = AppModel(settings: settings)
        XCTAssertEqual(model.sortProperty, .tag)
        XCTAssertFalse(model.sortAscending)

        model.sortProperty = .name
        model.sortAscending = true

        XCTAssertEqual(AppSettings(defaults: defaults).sortProperty, .name)
        XCTAssertTrue(AppSettings(defaults: defaults).sortAscending)
    }
}
