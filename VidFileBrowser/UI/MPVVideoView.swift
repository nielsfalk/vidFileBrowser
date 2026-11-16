import AppKit
import SwiftUI

struct MPVVideoView: NSViewRepresentable {
    let controller: PlayerController

    func makeNSView(context: Context) -> NSView {
        let view = VideoHostView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        controller.attachVideoView(view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

final class VideoHostView: NSView {
    override var isFlipped: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
}
