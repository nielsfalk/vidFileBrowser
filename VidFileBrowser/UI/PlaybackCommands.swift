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
        }
    }

    private var hasMedia: Bool {
        model.player.currentURL != nil || model.image != nil
    }
}
