import AppKit
import SwiftUI

/// Catches playback keys while the file browser is hidden in full screen.
struct FullScreenKeyView: NSViewRepresentable {
    var onPrevious: () -> Void
    var onNext: () -> Void
    var onShortcut: (BrowserShortcut) -> Void

    func makeNSView(context: Context) -> FullScreenKeyCatcherView {
        let view = FullScreenKeyCatcherView()
        view.onPrevious = onPrevious
        view.onNext = onNext
        view.onShortcut = onShortcut
        return view
    }

    func updateNSView(_ nsView: FullScreenKeyCatcherView, context: Context) {
        nsView.onPrevious = onPrevious
        nsView.onNext = onNext
        nsView.onShortcut = onShortcut

        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

final class FullScreenKeyCatcherView: NSView {
    var onPrevious: (() -> Void)?
    var onNext: (() -> Void)?
    var onShortcut: ((BrowserShortcut) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 126:
            onPrevious?()
            return
        case 125:
            onNext?()
            return
        default:
            break
        }

        if let shortcut = BrowserShortcut(event: event) {
            onShortcut?(shortcut)
            return
        }
        super.keyDown(with: event)
    }
}
