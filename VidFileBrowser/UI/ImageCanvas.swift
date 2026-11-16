import AppKit
import SwiftUI

struct ImageCanvas: NSViewRepresentable {
    let image: NSImage?

    func makeNSView(context: Context) -> ImageCanvasView {
        let view = ImageCanvasView()
        view.image = image
        return view
    }

    func updateNSView(_ nsView: ImageCanvasView, context: Context) {
        nsView.image = image
    }
}
