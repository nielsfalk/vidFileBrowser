import AppKit

final class ImageCanvasView: NSView {
    static let minZoom: CGFloat = 0.1
    static let maxZoom: CGFloat = 8

    var image: NSImage? {
        didSet {
            zoom = 1
            panOffset = .zero
            needsDisplay = true
        }
    }

    private(set) var zoom: CGFloat = 1
    private(set) var panOffset: NSPoint = .zero

    override var isFlipped: Bool { true }

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        bounds.fill()

        guard let image else { return }
        let rect = Self.targetRect(
            imageSize: image.size,
            in: bounds,
            zoom: zoom,
            pan: panOffset
        )
        image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    }

    override func magnify(with event: NSEvent) {
        setZoom(zoom * (1 + event.magnification))
    }

    override func scrollWheel(with event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard modifiers.contains(.option) || modifiers.contains(.command) else {
            super.scrollWheel(with: event)
            return
        }

        setZoom(zoom * (1 + event.scrollingDeltaY * 0.01))
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    override func mouseDragged(with event: NSEvent) {
        panOffset.x += event.deltaX
        panOffset.y += event.deltaY
        needsDisplay = true
    }

    func setZoom(_ value: CGFloat) {
        zoom = Self.clampedZoom(value)
        needsDisplay = true
    }

    static func clampedZoom(_ value: CGFloat) -> CGFloat {
        min(max(value, minZoom), maxZoom)
    }

    static func fittedRect(imageSize: NSSize, in bounds: NSRect) -> NSRect {
        guard imageSize.width > 0, imageSize.height > 0, bounds.width > 0, bounds.height > 0 else {
            return bounds
        }

        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let size = NSSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return NSRect(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    static func targetRect(imageSize: NSSize, in bounds: NSRect, zoom: CGFloat, pan: NSPoint) -> NSRect {
        let fitted = fittedRect(imageSize: imageSize, in: bounds)
        let clamped = clampedZoom(zoom)
        let size = NSSize(width: fitted.width * clamped, height: fitted.height * clamped)
        return NSRect(
            x: fitted.midX - size.width / 2 + pan.x,
            y: fitted.midY - size.height / 2 + pan.y,
            width: size.width,
            height: size.height
        )
    }
}
