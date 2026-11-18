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

    func testTrimmingSelectsAndPlaysTheTrimmedFile() throws {
        let trimmer = RecordingTrimmer()
        let model = try makeModel(trimmer: trimmer)

        model.trimLeft()
        try waitForTrim(model)

        let trimmed = try XCTUnwrap(model.items.first { $0.name == "clip_t.mov" })
        XCTAssertEqual(model.selection, [trimmed.id])
        XCTAssertEqual(model.player.currentURL, trimmed.url)
    }

    func testTrimKeepsTheItemAtItsListPosition() throws {
        let orderDirectory = directory.appendingPathComponent("Order", isDirectory: true)
        try FileManager.default.createDirectory(at: orderDirectory, withIntermediateDirectories: true)
        try Data().write(to: orderDirectory.appendingPathComponent("b.mov"))
        try Data().write(to: orderDirectory.appendingPathComponent("b-a.mov"))

        let trimmer = RecordingTrimmer()
        let model = try makeModel(trimmer: trimmer, in: orderDirectory)
        model.sortProperty = .name
        model.sortAscending = true

        XCTAssertEqual(model.items.map(\.name), ["b-a.mov", "b.mov"])
        let target = try XCTUnwrap(model.items.first { $0.name == "b.mov" })
        model.selection = [target.id]
        model.selectionDidChange()

        model.trimLeft()
        try waitForTrim(model)

        // Without pinning, the new name would move the file to the first row.
        XCTAssertEqual(model.items.map(\.name), ["b-a.mov", "b_t.mov"])

        model.sortProperty = .name
        XCTAssertEqual(model.items.map(\.name), ["b_t.mov", "b-a.mov"])
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
        let model = try makeModel(trimmer: trimmer, in: directory)
        model.selection = [try XCTUnwrap(model.items.first).id]
        model.selectionDidChange()
        return model
    }

    private func makeModel(trimmer: RecordingTrimmer, in directory: URL) throws -> AppModel {
        let player = PlayerController(player: StubPlayer())
        let model = AppModel(
            settings: AppSettings(defaults: defaults),
            player: player,
            trimService: trimmer,
            restoreLastFolder: false
        )
        model.open(directory)
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

    func trimReplacing(_ url: URL, range: TrimRange) throws -> URL {
        if let error { throw error }
        ranges.append(range)

        let destination = url.deletingLastPathComponent()
            .appendingPathComponent(TrimNaming.trimmedName(for: url.lastPathComponent))
        try FileManager.default.moveItem(at: url, to: destination)
        return destination
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
