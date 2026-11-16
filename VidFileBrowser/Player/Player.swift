import AppKit

enum PlayerState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case ended
    case failed(String)
}

struct PlayerPosition: Equatable {
    var time: Double = 0
    var duration: Double = 0
    var isSeekable: Bool = false

    var fraction: Double {
        guard duration > 0 else { return 0 }
        return min(max(time / duration, 0), 1)
    }
}

enum PlayerError: LocalizedError, Equatable {
    case unavailable(String)
    case cannotOpen(URL)

    var errorDescription: String? {
        switch self {
        case .unavailable(let message):
            message
        case .cannotOpen(let url):
            "Cannot open \(url.lastPathComponent)."
        }
    }
}

/// A media backend. All calls happen on the main actor; callbacks are
/// delivered on the main actor as well.
@MainActor
protocol Player: AnyObject {
    var onStateChange: ((PlayerState) -> Void)? { get set }
    var onPositionChange: ((PlayerPosition) -> Void)? { get set }
    var onEndOfFile: (() -> Void)? { get set }

    /// Gives the backend a view to render video into.
    func attach(view: NSView)
    func load(_ url: URL, autoplay: Bool) throws
    func play()
    func pause()
    func seek(to time: Double)
    func stop()
}
