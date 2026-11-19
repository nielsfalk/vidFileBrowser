import AppKit
import SwiftUI

/// Catches playback keys while the file browser is hidden in full screen.
struct FullScreenKeyView: NSViewRepresentable {
    var onShortcut: (BrowserShortcut) -> Void

    func makeNSView(context: Context) -> FullScreenKeyCatcherView {
        let view = FullScreenKeyCatcherView()
        view.onShortcut = onShortcut
        return view
    }

    func updateNSView(_ nsView: FullScreenKeyCatcherView, context: Context) {
        nsView.onShortcut = onShortcut

        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

final class FullScreenKeyCatcherView: NSView {
    var onShortcut: ((BrowserShortcut) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if let shortcut = BrowserShortcut(event: event) {
            onShortcut?(shortcut)
            return
        }
        super.keyDown(with: event)
    }
}
