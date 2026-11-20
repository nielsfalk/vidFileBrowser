import XCTest
@testable import VidFileBrowser

final class ProcessRunnerTests: XCTestCase {
    func testCancelAllStopsARunningProcess() {
        let runner = ProcessRunner()
        let finished = expectation(description: "process finished")

        DispatchQueue.global(qos: .userInitiated).async {
            _ = try? runner.run("/bin/sleep", arguments: ["30"])
            finished.fulfill()
        }

        // Give the runner a moment to start and register the process.
        Thread.sleep(forTimeInterval: 0.2)
        runner.cancelAll()

        wait(for: [finished], timeout: 5)
    }
}
