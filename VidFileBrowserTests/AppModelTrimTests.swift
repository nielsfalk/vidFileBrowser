import AppKit
import XCTest
@testable import VidFileBrowser

final class AppModelTrimTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!
    private var directory: URL!
    private var videoURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        suiteName = "AppModelTrimTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppModelTrimTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        videoURL = directory.appendingPathComponent("clip.mov")
        try Data().write(to: videoURL)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testTrimLeftUsesPlayheadToEnd() throws {
        let trimmer = RecordingTrimmer()
        let model = try makeModel(trimmer: trimmer)

        model.trimLeft()
        try waitForTrim(model)

        XCTAssertEqual(trimmer.ranges, [TrimRange(start: 4, end: 10)])
    }

    func testTrimRightUsesStartToPlayhead() throws {
        let trimmer = RecordingTrimmer()
        let model = try makeModel(trimmer: trimmer)

        model.trimRight()
        try waitForTrim(model)

        XCTAssertEqual(trimmer.ranges, [TrimRange(start: 0, end: 4)])
    }

    func testTrimErrorIsSurfaced() throws {
        let trimmer = RecordingTrimmer()
        trimmer.error = TrimError.failed("boom")
        let model = try makeModel(trimmer: trimmer)

        model.trimLeft()
        try waitForTrim(model)

        XCTAssertEqual(model.trimError, "boom")

        model.dismissTrimError()
        XCTAssertNil(model.trimError)
    }

    private func makeModel(trimmer: RecordingTrimmer) throws -> AppModel {
        let player = PlayerController(player: StubPlayer())
        let model = AppModel(
            settings: AppSettings(defaults: defaults),
            player: player,
            trimService: trimmer,
            restoreLastFolder: false
        )
        model.open(directory)
        model.selection = [try XCTUnwrap(model.items.first).id]
        model.selectionDidChange()
        return model
    }

    private func waitForTrim(_ model: AppModel) throws {
        let deadline = Date().addingTimeInterval(5)
        while model.isTrimming, Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
        XCTAssertFalse(model.isTrimming, "trim did not finish")
    }
}

private final class RecordingTrimmer: TrimServicing {
    var ranges: [TrimRange] = []
    var error: Error?

    func trimReplacing(_ url: URL, range: TrimRange) throws {
        if let error { throw error }
        ranges.append(range)
    }
}

private final class StubPlayer: Player {
    var onStateChange: ((PlayerState) -> Void)?
    var onPositionChange: ((PlayerPosition) -> Void)?
    var onEndOfFile: (() -> Void)?

    var time = 4.0
    var duration = 10.0

    func attach(view: NSView) {}

    func load(_ url: URL, autoplay: Bool) throws {
        onPositionChange?(PlayerPosition(time: time, duration: duration, isSeekable: true))
        onStateChange?(.playing)
    }

    func play() {}
    func pause() {}
    func seek(to time: Double) {}
    func stop() {}
}
