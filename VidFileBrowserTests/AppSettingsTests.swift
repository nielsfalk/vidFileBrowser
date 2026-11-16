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

    func testModelReadsAndWritesSortSettings() {
        let settings = AppSettings(defaults: defaults)
        settings.sortProperty = .label
        settings.sortAscending = false

        let model = AppModel(settings: settings)
        XCTAssertEqual(model.sortProperty, .label)
        XCTAssertFalse(model.sortAscending)

        model.sortProperty = .name
        model.sortAscending = true

        XCTAssertEqual(AppSettings(defaults: defaults).sortProperty, .name)
        XCTAssertTrue(AppSettings(defaults: defaults).sortAscending)
    }
}
