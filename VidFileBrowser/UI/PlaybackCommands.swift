import SwiftUI

struct PlaybackCommands: Commands {
    let model: AppModel

    var body: some Commands {
        CommandMenu("Playback") {
            Button("Play/Pause", action: togglePlayPause)
                .keyboardShortcut(.space, modifiers: [])

            Divider()

            Button("Back 10 Seconds") {
                skip(by: -10)
            }
            .keyboardShortcut(.leftArrow, modifiers: [])

            Button("Forward 10 Seconds") {
                skip(by: 10)
            }
            .keyboardShortcut(.rightArrow, modifiers: [])

            Divider()

            Button("Back 30 Seconds") {
                skip(by: -30)
            }
            .keyboardShortcut(",", modifiers: [])

            Button("Forward 30 Seconds") {
                skip(by: 30)
            }
            .keyboardShortcut(".", modifiers: [])

            Divider()

            Button("Trim Left at Playhead") {
                if hasVideo, !model.isTrimming {
                    model.trimLeft()
                }
            }
            .keyboardShortcut("n", modifiers: [])

            Button("Trim Right at Playhead") {
                if hasVideo, !model.isTrimming {
                    model.trimRight()
                }
            }
            .keyboardShortcut("m", modifiers: [])
        }
    }

    private func togglePlayPause() {
        guard hasMedia else { return }
        if model.image != nil {
            return
        }
        model.player.togglePlayPause()
    }

    private func skip(by seconds: Double) {
        guard hasMedia, model.image == nil else { return }
        model.player.skip(by: seconds)
    }

    private var hasMedia: Bool {
        model.player.currentURL != nil || model.image != nil
    }

    private var hasVideo: Bool {
        model.player.currentURL != nil
    }
}
