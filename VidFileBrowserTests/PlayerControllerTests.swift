import AppKit
import XCTest
@testable import VidFileBrowser

final class PlayerControllerTests: XCTestCase {
    func testLoadDelegatesToBackend() throws {
        let player = MockPlayer()
        let controller = PlayerController(player: player)
        let url = URL(fileURLWithPath: "/tmp/movie.mp4")

        controller.load(url)

        XCTAssertEqual(player.loadedURL, url)
        XCTAssertTrue(player.didAutoplay)
        XCTAssertEqual(controller.currentURL, url)
    }

    func testLoadFailureIsReported() {
        let player = MockPlayer()
        player.loadError = PlayerError.unavailable("libmpv missing")
        let controller = PlayerController(player: player)

        controller.load(URL(fileURLWithPath: "/tmp/movie.mp4"))

        XCTAssertEqual(controller.state, .failed("libmpv missing"))
    }

    func testStateChangesAreForwarded() {
        let player = MockPlayer()
        let controller = PlayerController(player: player)

        player.report(state: .playing)
        XCTAssertEqual(controller.state, .playing)

        player.report(state: .paused)
        XCTAssertEqual(controller.state, .paused)
    }

    func testPositionChangesAreForwarded() {
        let player = MockPlayer()
        let controller = PlayerController(player: player)
        let position = PlayerPosition(time: 12, duration: 60, isSeekable: true)

        player.report(position: position)

        XCTAssertEqual(controller.position, position)
        XCTAssertEqual(controller.duration, 60)
        XCTAssertEqual(controller.currentTime, 12)
    }

    func testEndOfFileEndsPlayback() {
        let player = MockPlayer()
        let controller = PlayerController(player: player)

        player.reportEndOfFile()

        XCTAssertEqual(controller.state, .ended)
    }

    func testEndOfFileKeepsTheLastFrame() {
        let player = MockPlayer()
        let controller = PlayerController(player: player)
        controller.load(URL(fileURLWithPath: "/tmp/movie.mp4"))
        player.report(position: PlayerPosition(time: 59.8, duration: 60, isSeekable: true))

        player.report(state: .playing)
        player.reportEndOfFile()

        XCTAssertEqual(controller.state, .ended)
        XCTAssertEqual(controller.currentTime, 59.8)
        XCTAssertNotNil(controller.currentURL)
        XCTAssertEqual(player.pauseCount, 0)
    }

    func testPlayingAfterTheEndRestartsFromTheBeginning() {
        let player = MockPlayer()
        let controller = PlayerController(player: player)
        controller.load(URL(fileURLWithPath: "/tmp/movie.mp4"))
        player.reportEndOfFile()

        controller.play()

        XCTAssertEqual(player.seekedTime, 0)
        XCTAssertEqual(player.playCount, 1)
    }

    func testTogglePlayPause() {
        let player = MockPlayer()
        let controller = PlayerController(player: player)

        controller.togglePlayPause()
        XCTAssertEqual(player.playCount, 1)

        player.report(state: .playing)
        controller.togglePlayPause()
        XCTAssertEqual(player.pauseCount, 1)
    }

    func testSkipClampsToDuration() {
        let player = MockPlayer()
        let controller = PlayerController(player: player)
        player.report(position: PlayerPosition(time: 55, duration: 60, isSeekable: true))

        controller.skip(by: 30)
        XCTAssertEqual(player.seekedTime, 60)

        controller.skip(by: -100)
        XCTAssertEqual(player.seekedTime, 0)
    }

    func testStopResetsState() {
        let player = MockPlayer()
        let controller = PlayerController(player: player)
        controller.load(URL(fileURLWithPath: "/tmp/movie.mp4"))

        controller.stop()

        XCTAssertNil(controller.currentURL)
        XCTAssertEqual(controller.state, .idle)
        XCTAssertEqual(controller.position, PlayerPosition())
        XCTAssertEqual(player.stopCount, 1)
    }
}

private final class MockPlayer: Player {
    var onStateChange: ((PlayerState) -> Void)?
    var onPositionChange: ((PlayerPosition) -> Void)?
    var onEndOfFile: (() -> Void)?

    var loadError: Error?
    var loadedURL: URL?
    var didAutoplay = false
    var playCount = 0
    var pauseCount = 0
    var stopCount = 0
    var seekedTime: Double?

    func attach(view: NSView) {}

    func load(_ url: URL, autoplay: Bool) throws {
        if let loadError { throw loadError }
        loadedURL = url
        didAutoplay = autoplay
    }

    func play() { playCount += 1 }
    func pause() { pauseCount += 1 }
    func seek(to time: Double) { seekedTime = time }
    func stop() { stopCount += 1 }

    func report(state: PlayerState) {
        onStateChange?(state)
    }

    func report(position: PlayerPosition) {
        onPositionChange?(position)
    }

    func reportEndOfFile() {
        onEndOfFile?()
    }
}
