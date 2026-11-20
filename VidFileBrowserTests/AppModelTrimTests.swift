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

    func testTwoFilesCanBeTrimmedAtTheSameTime() throws {
        try Data().write(to: directory.appendingPathComponent("second.mov"))

        let trimmer = GatedTrimmer()
        let model = try makeModel(trimmer: trimmer)

        model.trimLeft()
        model.selection = [try XCTUnwrap(model.items.first { $0.name == "second.mov" }).id]
        model.selectionDidChange()
        model.trimLeft()

        XCTAssertEqual(model.trimCount, 2)
        XCTAssertTrue(model.isTrimming)

        trimmer.releaseAll()
        try waitForTrim(model)

        XCTAssertEqual(trimmer.callCount, 2)
        XCTAssertEqual(Set(model.items.map(\.name)), ["clip_t.mov", "second_t.mov"])
        XCTAssertEqual(model.trimCount, 0)
    }

    func testAFinishedTrimDoesNotInterruptAnotherFile() throws {
        try Data().write(to: directory.appendingPathComponent("second.mov"))

        let trimmer = GatedTrimmer()
        let model = try makeModel(trimmer: trimmer)

        // Start trimming clip.mov, then move on to second.mov while it runs.
        model.trimLeft()
        let second = try XCTUnwrap(model.items.first { $0.name == "second.mov" })
        model.selection = [second.id]
        model.selectionDidChange()

        trimmer.releaseAll()
        try waitForTrim(model)

        XCTAssertEqual(model.player.currentURL, second.url)
        XCTAssertEqual(model.selection, [second.id])
    }

    func testCancellingTrimsLeavesTheFileAndSkipsTheError() throws {
        let trimmer = GatedTrimmer()
        let model = try makeModel(trimmer: trimmer)

        model.trimLeft()
        XCTAssertEqual(model.trimCount, 1)

        model.cancelTrims()
        XCTAssertEqual(trimmer.cancelCalls, 1)

        try waitForTrim(model)

        XCTAssertTrue(FileManager.default.fileExists(atPath: videoURL.path))
        XCTAssertNil(model.trimError)
    }

    func testWaitingForTrimsCallsBackAfterTheLastOne() throws {
        let trimmer = GatedTrimmer()
        let model = try makeModel(trimmer: trimmer)

        var finished = false
        model.trimLeft()
        model.waitForTrimsToFinish { finished = true }
        XCTAssertFalse(finished)

        trimmer.releaseAll()
        try waitForTrim(model)

        XCTAssertTrue(finished)
    }

    private func makeModel(trimmer: TrimServicing) throws -> AppModel {
        let model = try makeModel(trimmer: trimmer, in: directory)
        model.selection = [try XCTUnwrap(model.items.first).id]
        model.selectionDidChange()
        return model
    }

    private func makeModel(trimmer: TrimServicing, in directory: URL) throws -> AppModel {
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

/// Keeps trims running until the test releases them, so parallel work and
/// cancellation can be observed.
private final class GatedTrimmer: TrimServicing {
    private let lock = NSLock()
    private let gate = DispatchSemaphore(value: 0)
    private var ranges: [TrimRange] = []
    private var isCancelled = false
    private var cancellations = 0

    var callCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return ranges.count
    }

    var cancelCalls: Int {
        lock.lock()
        defer { lock.unlock() }
        return cancellations
    }

    func releaseAll() {
        for _ in 0..<8 {
            gate.signal()
        }
    }

    func trimReplacing(_ url: URL, range: TrimRange) throws -> URL {
        lock.lock()
        ranges.append(range)
        lock.unlock()

        gate.wait()

        lock.lock()
        let cancelled = isCancelled
        lock.unlock()
        if cancelled {
            throw TrimError.failed("Cancelled")
        }

        let destination = url.deletingLastPathComponent()
            .appendingPathComponent(TrimNaming.trimmedName(for: url.lastPathComponent))
        try FileManager.default.moveItem(at: url, to: destination)
        return destination
    }

    func cancelAll() {
        lock.lock()
        isCancelled = true
        cancellations += 1
        lock.unlock()
        releaseAll()
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
