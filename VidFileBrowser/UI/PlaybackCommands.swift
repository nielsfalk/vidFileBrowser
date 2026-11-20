import AppKit
import SwiftUI

struct PlaybackCommands: Commands {
    let model: AppModel

    var body: some Commands {
        CommandMenu("Playback") {
            Button("Play/Pause", action: togglePlayPause)
                .keyboardShortcut(.space, modifiers: [])

            Divider()

            Button("Back 40 Seconds") {
                skip(by: -40)
            }
            .keyboardShortcut(.upArrow, modifiers: [])

            Button("Forward 40 Seconds") {
                skip(by: 40)
            }
            .keyboardShortcut(.downArrow, modifiers: [])

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
                if hasVideo, !model.isTrimmingCurrentItem {
                    model.trimLeft()
                }
            }
            .keyboardShortcut("n", modifiers: [])

            Button("Trim Right at Playhead") {
                if hasVideo, !model.isTrimmingCurrentItem {
                    model.trimRight()
                }
            }
            .keyboardShortcut("m", modifiers: [])

            Divider()

            Button("Toggle Full Screen", action: toggleFullScreen)
                .keyboardShortcut("f", modifiers: [])

            Button("Exit Full Screen") {
                if isFullScreen {
                    toggleFullScreen()
                }
            }
            .keyboardShortcut(.escape, modifiers: [])
        }
    }

    private func toggleFullScreen() {
        NSApp.keyWindow?.toggleFullScreen(nil)
    }

    private var isFullScreen: Bool {
        NSApp.keyWindow?.styleMask.contains(.fullScreen) ?? false
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
