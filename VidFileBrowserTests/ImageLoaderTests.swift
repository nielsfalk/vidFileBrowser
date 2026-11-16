import AppKit
import XCTest
@testable import VidFileBrowser

final class ImageLoaderTests: XCTestCase {
    func testLoadsPNG() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ImageLoaderTests-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: url) }
        try TestImage.pngData(width: 8, height: 4).write(to: url)

        let image = try XCTUnwrap(ImageLoader.image(at: url))

        XCTAssertEqual(Int(image.size.width), 8)
        XCTAssertEqual(Int(image.size.height), 4)
    }

    func testMissingFileGivesNoImage() {
        XCTAssertNil(ImageLoader.image(at: URL(fileURLWithPath: "/tmp/does-not-exist.png")))
    }

    func testInvalidDataGivesNoImage() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ImageLoaderTests-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("not an image".utf8).write(to: url)

        XCTAssertNil(ImageLoader.image(at: url))
    }

    func testFittedRectKeepsAspectRatio() {
        let bounds = NSRect(x: 0, y: 0, width: 400, height: 200)

        let wide = ImageCanvasView.fittedRect(imageSize: NSSize(width: 200, height: 100), in: bounds)
        XCTAssertEqual(wide, bounds)

        let tall = ImageCanvasView.fittedRect(imageSize: NSSize(width: 100, height: 400), in: bounds)
        XCTAssertEqual(tall.size.width, 50, accuracy: 0.01)
        XCTAssertEqual(tall.size.height, 200, accuracy: 0.01)
        XCTAssertEqual(tall.midX, 200, accuracy: 0.01)
    }

    func testZoomIsClamped() {
        XCTAssertEqual(ImageCanvasView.clampedZoom(0.01), ImageCanvasView.minZoom)
        XCTAssertEqual(ImageCanvasView.clampedZoom(50), ImageCanvasView.maxZoom)
        XCTAssertEqual(ImageCanvasView.clampedZoom(2), 2)
    }

    func testTargetRectAppliesZoomAndPan() {
        let bounds = NSRect(x: 0, y: 0, width: 400, height: 200)
        let size = NSSize(width: 200, height: 100)

        let zoomed = ImageCanvasView.targetRect(imageSize: size, in: bounds, zoom: 2, pan: .zero)
        XCTAssertEqual(zoomed.size, NSSize(width: 800, height: 400))
        XCTAssertEqual(zoomed.midX, bounds.midX)
        XCTAssertEqual(zoomed.midY, bounds.midY)

        let panned = ImageCanvasView.targetRect(imageSize: size, in: bounds, zoom: 1, pan: NSPoint(x: 10, y: -5))
        XCTAssertEqual(panned.midX, bounds.midX + 10)
        XCTAssertEqual(panned.midY, bounds.midY - 5)
    }
}

enum TestImage {
    static func pngData(width: Int, height: Int) throws -> Data {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        NSColor.systemBlue.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        image.unlockFocus()

        let tiff = try XCTUnwrap(image.tiffRepresentation)
        let bitmap = try XCTUnwrap(NSBitmapImageRep(data: tiff))
        return try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
    }
}
