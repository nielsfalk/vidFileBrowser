import AppKit
import SwiftUI

/// Hosts mpv's render API output. mpv draws into this view's OpenGL context.
final class MPVOpenGLView: NSOpenGLView {
    weak var player: MPVPlayer?

    private static let pixelFormatAttributes: [NSOpenGLPixelFormatAttribute] = [
        NSOpenGLPixelFormatAttribute(NSOpenGLPFAOpenGLProfile),
        NSOpenGLPixelFormatAttribute(NSOpenGLProfileVersion3_2Core),
        NSOpenGLPixelFormatAttribute(NSOpenGLPFAColorSize), 24,
        NSOpenGLPixelFormatAttribute(NSOpenGLPFAAlphaSize), 8,
        NSOpenGLPixelFormatAttribute(NSOpenGLPFADoubleBuffer),
        NSOpenGLPixelFormatAttribute(NSOpenGLPFAAccelerated), 0
    ]

    static func make() -> MPVOpenGLView {
        let format = NSOpenGLPixelFormat(attributes: pixelFormatAttributes)
            ?? NSOpenGLPixelFormat()
        guard let view = MPVOpenGLView(frame: .zero, pixelFormat: format) else {
            fatalError("Could not create the OpenGL view")
        }
        view.wantsBestResolutionOpenGLSurface = true
        return view
    }

    override var isOpaque: Bool { true }

    override var acceptsFirstResponder: Bool { false }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            window?.toggleFullScreen(nil)
            return
        }
        super.mouseDown(with: event)
    }

    override func prepareOpenGL() {
        super.prepareOpenGL()
        openGLContext?.makeCurrentContext()
    }

    override func reshape() {
        super.reshape()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        player?.render(in: self)
    }

    deinit {
        player?.detach(view: self)
    }
}

struct MPVVideoView: NSViewRepresentable {
    let controller: PlayerController

    func makeNSView(context: Context) -> MPVOpenGLView {
        let view = MPVOpenGLView.make()
        controller.attachVideoView(view)
        return view
    }

    func updateNSView(_ nsView: MPVOpenGLView, context: Context) {}
}
