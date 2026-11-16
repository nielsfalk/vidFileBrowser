import AppKit
import Foundation
import Observation

/// Observable facade over a `Player` backend for SwiftUI.
@Observable
final class PlayerController {
    private(set) var state: PlayerState = .idle
    private(set) var position = PlayerPosition()
    private(set) var currentURL: URL?

    private var player: Player

    init(player: Player? = nil) {
        self.player = player ?? UnavailablePlayer()
        connect()
    }

    var duration: Double { position.duration }
    var currentTime: Double { position.time }

    func replacePlayer(_ player: Player) {
        self.player.stop()
        self.player = player
        connect()
    }

    func attachVideoView(_ view: NSView) {
        player.attach(view: view)
    }

    func load(_ url: URL, autoplay: Bool = true) {
        currentURL = url
        state = .loading
        position = PlayerPosition()

        do {
            try player.load(url, autoplay: autoplay)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func play() {
        if state == .ended {
            player.seek(to: 0)
            position.time = 0
        }
        player.play()
    }

    func pause() {
        player.pause()
    }

    func togglePlayPause() {
        if state == .playing {
            player.pause()
        } else {
            player.play()
        }
    }

    func seek(to time: Double) {
        player.seek(to: time)
    }

    func skip(by seconds: Double) {
        player.seek(to: max(0, min(currentTime + seconds, duration)))
    }

    func stop() {
        player.stop()
        currentURL = nil
        state = .idle
        position = PlayerPosition()
    }

    private func connect() {
        player.onStateChange = { [weak self] state in
            self?.state = state
        }
        player.onPositionChange = { [weak self] position in
            self?.position = position
        }
        player.onEndOfFile = { [weak self] in
            self?.state = .ended
        }
    }
}
