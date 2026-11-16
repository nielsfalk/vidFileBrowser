import XCTest
@testable import VidFileBrowser

final class DependencyLocatorTests: XCTestCase {
    private var root: URL!
    private let fileManager = FileManager.default

    override func setUpWithError() throws {
        root = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? fileManager.removeItem(at: root)
    }

    func testFindsBothTools() throws {
        try installDependencies(in: "homebrew")
        let prefix = root.appendingPathComponent("homebrew").path

        let dependencies = DependencyLocator.locate(prefixes: [prefix])

        XCTAssertEqual(dependencies.libmpvPath, "\(prefix)/lib/libmpv.dylib")
        XCTAssertEqual(dependencies.ffmpegPath, "\(prefix)/bin/ffmpeg")
        XCTAssertTrue(dependencies.isSatisfied)
    }

    func testReportsMissingTools() {
        let dependencies = DependencyLocator.locate(prefixes: [root.path])

        XCTAssertNil(dependencies.libmpvPath)
        XCTAssertNil(dependencies.ffmpegPath)
        XCTAssertFalse(dependencies.isSatisfied)
    }

    func testUsesFirstPrefixThatHasTheTools() throws {
        try installDependencies(in: "intel")
        let appleSilicon = root.appendingPathComponent("apple-silicon").path
        let intel = root.appendingPathComponent("intel").path

        let dependencies = DependencyLocator.locate(prefixes: [appleSilicon, intel])

        XCTAssertEqual(dependencies.ffmpegPath, "\(intel)/bin/ffmpeg")
        XCTAssertEqual(dependencies.libmpvPath, "\(intel)/lib/libmpv.dylib")
    }

    func testInstallCommand() {
        XCTAssertEqual(Dependencies.installCommand, "brew install mpv ffmpeg")
    }

    private func installDependencies(in prefix: String) throws {
        let libDirectory = root.appendingPathComponent("\(prefix)/lib")
        let binDirectory = root.appendingPathComponent("\(prefix)/bin")
        try fileManager.createDirectory(at: libDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: binDirectory, withIntermediateDirectories: true)

        let libmpv = libDirectory.appendingPathComponent("libmpv.dylib")
        XCTAssertTrue(fileManager.createFile(atPath: libmpv.path, contents: Data()))

        let ffmpeg = binDirectory.appendingPathComponent("ffmpeg")
        XCTAssertTrue(fileManager.createFile(atPath: ffmpeg.path, contents: Data("#!/bin/sh\n".utf8)))
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: ffmpeg.path)
    }
}
