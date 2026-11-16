import SwiftUI

struct PlaybackCommands: Commands {
    let model: AppModel

    var body: some Commands {
        CommandMenu("Playback") {
            Button("Play/Pause") {
                model.player.togglePlayPause()
            }
            .keyboardShortcut(.space, modifiers: [])
            .disabled(!hasMedia)

            Divider()

            Button("Back 10 Seconds") {
                model.player.skip(by: -10)
            }
            .keyboardShortcut(.leftArrow, modifiers: [])
            .disabled(!hasMedia)

            Button("Forward 10 Seconds") {
                model.player.skip(by: 10)
            }
            .keyboardShortcut(.rightArrow, modifiers: [])
            .disabled(!hasMedia)

            Divider()

            Button("Back 30 Seconds") {
                model.player.skip(by: -30)
            }
            .keyboardShortcut(",", modifiers: [])
            .disabled(!hasMedia)

            Button("Forward 30 Seconds") {
                model.player.skip(by: 30)
            }
            .keyboardShortcut(".", modifiers: [])
            .disabled(!hasMedia)

            Divider()

            Button("Trim Left at Playhead") {
                model.trimLeft()
            }
            .keyboardShortcut("n", modifiers: [])
            .disabled(!hasVideo || model.isTrimming)

            Button("Trim Right at Playhead") {
                model.trimRight()
            }
            .keyboardShortcut("m", modifiers: [])
            .disabled(!hasVideo || model.isTrimming)
        }
    }

    private var hasMedia: Bool {
        model.player.currentURL != nil || model.image != nil
    }

    private var hasVideo: Bool {
        model.player.currentURL != nil
    }
}
