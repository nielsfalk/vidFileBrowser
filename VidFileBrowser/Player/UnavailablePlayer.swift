import AppKit

/// Used when the media backend is not available. Opening a file reports why.
@MainActor
final class UnavailablePlayer: Player {
    var onStateChange: ((PlayerState) -> Void)?
    var onPositionChange: ((PlayerPosition) -> Void)?
    var onEndOfFile: (() -> Void)?

    private let reason: String

    init(reason: String = "libmpv is not installed. Run brew install mpv ffmpeg.") {
        self.reason = reason
    }

    func attach(view: NSView) {}

    func load(_ url: URL, autoplay: Bool) throws {
        throw PlayerError.unavailable(reason)
    }

    func play() {}
    func pause() {}
    func seek(to time: Double) {}
    func stop() {}
}
