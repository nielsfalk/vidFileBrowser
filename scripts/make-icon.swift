import AppKit

func draw(size: CGFloat) {
    let inset = size * 0.06
    let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let background = NSBezierPath(roundedRect: rect, xRadius: size * 0.21, yRadius: size * 0.21)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.12, green: 0.32, blue: 0.88, alpha: 1),
        NSColor(calibratedRed: 0.36, green: 0.62, blue: 1.00, alpha: 1)
    ])!
    gradient.draw(in: background, angle: -90)

    let width = size * 0.30
    let height = size * 0.36
    let centerX = size / 2 + size * 0.02
    let centerY = size / 2

    let triangle = NSBezierPath()
    triangle.move(to: NSPoint(x: centerX - width / 2, y: centerY - height / 2))
    triangle.line(to: NSPoint(x: centerX - width / 2, y: centerY + height / 2))
    triangle.line(to: NSPoint(x: centerX + width / 2, y: centerY))
    triangle.close()
    NSColor.white.setFill()
    triangle.fill()
}

func png(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw(size: CGFloat(pixels))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let files: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
]
for (name, pixelSize) in files {
    try! png(pixels: pixelSize).write(to: output.appendingPathComponent(name))
}
