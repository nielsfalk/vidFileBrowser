import AppKit
import SwiftUI

struct WindowConfigurator: NSViewRepresentable {
    private static let frameAutosaveName = "VidFileBrowserMainWindow"

    var title: String
    var onFullScreenChange: ((Bool) -> Void)? = nil

    func makeNSView(context: Context) -> WindowProbeView {
        let view = WindowProbeView()
        view.title = title
        view.onWindow = { window in
            window.setFrameAutosaveName(Self.frameAutosaveName)
        }
        view.onFullScreenChange = onFullScreenChange
        return view
    }

    func updateNSView(_ nsView: WindowProbeView, context: Context) {
        nsView.title = title
        nsView.window?.title = title
        nsView.onFullScreenChange = onFullScreenChange
    }
}

final class WindowProbeView: NSView {
    var title: String? {
        didSet {
            if let title, window?.title != title {
                window?.title = title
            }
        }
    }
    var onWindow: ((NSWindow) -> Void)?
    var onFullScreenChange: ((Bool) -> Void)?
    private var observers: [NSObjectProtocol] = []

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        onWindow?(window)
        if let title {
            window.title = title
        }

        observers.forEach(NotificationCenter.default.removeObserver)
        let center = NotificationCenter.default
        observers = [
            center.addObserver(
                forName: NSWindow.didEnterFullScreenNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                self?.onFullScreenChange?(true)
            },
            center.addObserver(
                forName: NSWindow.didExitFullScreenNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                self?.onFullScreenChange?(false)
            }
        ]
        onFullScreenChange?(window.styleMask.contains(.fullScreen))
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }
}
