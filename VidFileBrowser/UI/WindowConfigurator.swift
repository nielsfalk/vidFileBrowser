import AppKit
import SwiftUI

struct WindowConfigurator: NSViewRepresentable {
    private static let frameAutosaveName = "VidFileBrowserMainWindow"

    func makeNSView(context: Context) -> WindowProbeView {
        let view = WindowProbeView()
        view.onWindow = { window in
            window.setFrameAutosaveName(Self.frameAutosaveName)
        }
        return view
    }

    func updateNSView(_ nsView: WindowProbeView, context: Context) {}
}

final class WindowProbeView: NSView {
    var onWindow: ((NSWindow) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window {
            onWindow?(window)
        }
    }
}
