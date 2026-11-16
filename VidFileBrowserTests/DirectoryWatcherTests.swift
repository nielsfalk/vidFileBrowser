import XCTest
@testable import VidFileBrowser

final class DirectoryWatcherTests: XCTestCase {
    func testReportsContentChanges() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DirectoryWatcherTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let changed = expectation(description: "directory change reported")
        changed.assertForOverFulfill = false

        let watcher = DirectoryWatcher()
        addTeardownBlock { watcher.stop() }
        watcher.watch(directory) {
            changed.fulfill()
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            try? "hello".write(
                to: directory.appendingPathComponent("new.txt"),
                atomically: true,
                encoding: .utf8
            )
        }

        wait(for: [changed], timeout: 5)
    }
}
