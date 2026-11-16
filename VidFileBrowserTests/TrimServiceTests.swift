import XCTest
@testable import VidFileBrowser

final class TrimServiceTests: XCTestCase {
    private let input = URL(fileURLWithPath: "/tmp/in.mov")
    private let output = URL(fileURLWithPath: "/tmp/out.mov")

    func testParsesKeyframeTimes() {
        let output = "0.000000\n2.002000\n4.004000\n"
        XCTAssertEqual(TrimService.parseKeyframeTimes(output), [0, 2.002, 4.004])
    }

    func testParsesCommaSeparatedKeyframeTimes() {
        XCTAssertEqual(TrimService.parseKeyframeTimes("1.5,3.5"), [1.5, 3.5])
    }

    func testNearestKeyframeSnapsBackwards() {
        let times: [Double] = [0, 2, 4, 6]
        XCTAssertEqual(TrimService.nearestKeyframe(times, atOrBefore: 5), 4)
        XCTAssertEqual(TrimService.nearestKeyframe(times, atOrBefore: 6), 6)
        XCTAssertNil(TrimService.nearestKeyframe(times, atOrBefore: -1))
    }

    func testTrimArgumentsAreLossless() {
        let arguments = TrimService.trimArguments(input: input, start: 2, duration: 3.5, output: output)

        XCTAssertTrue(arguments.contains("-c"))
        XCTAssertEqual(arguments[arguments.firstIndex(of: "-c")! + 1], "copy")
        XCTAssertEqual(arguments[arguments.firstIndex(of: "-ss")! + 1], "2.000")
        XCTAssertEqual(arguments[arguments.firstIndex(of: "-t")! + 1], "3.500")
        XCTAssertEqual(arguments.last, output.path)
    }

    func testTrimUsesKeyframeFromProbe() throws {
        let runner = FakeRunner(results: [
            ProcessResult(status: 0, stdout: "1.0\n2.0\n3.0\n", stderr: ""),
            ProcessResult(status: 0, stdout: "", stderr: "")
        ])
        let service = TrimService(ffmpegPath: "/fake/ffmpeg", ffprobePath: "/fake/ffprobe", runner: runner)

        try service.trim(input: input, range: TrimRange(start: 2.5, end: 8), output: output)

        XCTAssertEqual(runner.commands.count, 2)
        XCTAssertEqual(runner.commands[0].executable, "/fake/ffprobe")
        let ffmpegArguments = runner.commands[1].arguments
        XCTAssertEqual(ffmpegArguments[ffmpegArguments.firstIndex(of: "-ss")! + 1], "2.000")
        XCTAssertEqual(ffmpegArguments[ffmpegArguments.firstIndex(of: "-t")! + 1], "6.000")
    }

    func testFailureIsReported() {
        let runner = FakeRunner(results: [ProcessResult(status: 1, stdout: "", stderr: "boom")])
        let service = TrimService(ffmpegPath: "/fake/ffmpeg", ffprobePath: "/fake/ffprobe", runner: runner)

        XCTAssertThrowsError(try service.trim(input: input, range: TrimRange(start: 1, end: 3), output: output)) { error in
            XCTAssertEqual(error as? TrimError, .failed("boom"))
        }
    }

    func testMissingToolsAreReported() {
        let service = TrimService(ffmpegPath: nil, ffprobePath: nil, runner: FakeRunner(results: []))

        XCTAssertThrowsError(try service.trim(input: input, range: TrimRange(start: 1, end: 3), output: output)) { error in
            XCTAssertEqual(error as? TrimError, .ffmpegMissing)
        }
    }

    func testInvalidRangeIsRejected() {
        let service = TrimService(ffmpegPath: "/fake/ffmpeg", ffprobePath: "/fake/ffprobe", runner: FakeRunner(results: []))

        XCTAssertThrowsError(try service.trim(input: input, range: TrimRange(start: 3, end: 2), output: output)) { error in
            XCTAssertEqual(error as? TrimError, .invalidRange)
        }
    }
    func testTrimReplacingSwapsTheFileAndTrashesTheOriginal() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TrimServiceTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let file = directory.appendingPathComponent("clip.mov")
        try Data("original".utf8).write(to: file)

        let trash = FakeTrash()
        let runner = FakeRunner(results: [])
        runner.onRun = { executable, arguments in
            if executable.contains("ffprobe") {
                return ProcessResult(status: 0, stdout: "0.0\n", stderr: "")
            }
            let outputPath = arguments.last!
            try? Data("trimmed".utf8).write(to: URL(fileURLWithPath: outputPath))
            return ProcessResult(status: 0, stdout: "", stderr: "")
        }
        let service = TrimService(
            ffmpegPath: "/fake/ffmpeg",
            ffprobePath: "/fake/ffprobe",
            runner: runner,
            trash: trash
        )

        try service.trimReplacing(file, range: TrimRange(start: 1, end: 2))

        let trimmed = directory.appendingPathComponent("clip_t.mov")
        XCTAssertEqual(trash.trashedURLs, [file])
        XCTAssertEqual(try String(contentsOf: trimmed, encoding: .utf8), "trimmed")
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        let leftovers = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertEqual(leftovers, ["clip_t.mov"])
    }

    func testMissingKeyframeReencodesWhenConfirmed() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TrimServiceTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let file = directory.appendingPathComponent("clip.mov")
        try Data("original".utf8).write(to: file)

        var confirmations = 0
        var ffmpegCommands: [[String]] = []
        let runner = FakeRunner(results: [])
        runner.onRun = { executable, arguments in
            if executable.contains("ffprobe") {
                return ProcessResult(status: 0, stdout: "", stderr: "")
            }
            ffmpegCommands.append(arguments)
            let outputPath = arguments.last!
            try? Data("trimmed".utf8).write(to: URL(fileURLWithPath: outputPath))
            return ProcessResult(status: 0, stdout: "", stderr: "")
        }
        let service = TrimService(
            ffmpegPath: "/fake/ffmpeg",
            ffprobePath: "/fake/ffprobe",
            runner: runner,
            trash: FakeTrash(),
            confirmReencode: { _, _ in
                confirmations += 1
                return true
            }
        )

        try service.trimReplacing(file, range: TrimRange(start: 2, end: 4))

        XCTAssertEqual(confirmations, 1)
        XCTAssertEqual(ffmpegCommands.count, 1)
        let command = ffmpegCommands[0]
        XCTAssertTrue(command.contains("libx264"))
        XCTAssertEqual(command[command.firstIndex(of: "-c:a")! + 1], "copy")
        XCTAssertEqual(command[command.firstIndex(of: "-ss")! + 1], "2.000")
        XCTAssertEqual(command[command.firstIndex(of: "-t")! + 1], "2.000")
    }

    func testKeyframePromptIsAskedOnTheMainThread() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TrimServiceTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let file = directory.appendingPathComponent("clip.mov")
        try Data("original".utf8).write(to: file)

        let asked = expectation(description: "keyframe prompt shown")
        var askedOnMainThread = false
        let runner = FakeRunner(results: [])
        runner.onRun = { executable, arguments in
            if executable.contains("ffprobe") {
                return ProcessResult(status: 0, stdout: "", stderr: "")
            }
            let outputPath = arguments.last!
            try? Data("trimmed".utf8).write(to: URL(fileURLWithPath: outputPath))
            return ProcessResult(status: 0, stdout: "", stderr: "")
        }
        let service = TrimService(
            ffmpegPath: "/fake/ffmpeg",
            ffprobePath: "/fake/ffprobe",
            runner: runner,
            trash: FakeTrash(),
            confirmReencode: { _, _ in
                askedOnMainThread = Thread.isMainThread
                asked.fulfill()
                return true
            }
        )

        DispatchQueue.global().async {
            try? service.trimReplacing(file, range: TrimRange(start: 2, end: 4))
        }
        wait(for: [asked], timeout: 5)

        XCTAssertTrue(askedOnMainThread)
    }

    func testMissingKeyframeIsAnErrorWhenDeclined() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TrimServiceTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let file = directory.appendingPathComponent("clip.mov")
        try Data("original".utf8).write(to: file)

        let trash = FakeTrash()
        let service = TrimService(
            ffmpegPath: "/fake/ffmpeg",
            ffprobePath: "/fake/ffprobe",
            runner: FakeRunner(results: [ProcessResult(status: 0, stdout: "", stderr: "")]),
            trash: trash,
            confirmReencode: { _, _ in false }
        )

        XCTAssertThrowsError(try service.trimReplacing(file, range: TrimRange(start: 2, end: 4))) { error in
            XCTAssertEqual(error as? TrimError, .noKeyframe)
        }
        XCTAssertTrue(trash.trashedURLs.isEmpty)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "original")
    }

    func testTrimReplacingKeepsTheOriginalOnFailure() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TrimServiceTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let file = directory.appendingPathComponent("clip.mov")
        try Data("original".utf8).write(to: file)

        let trash = FakeTrash()
        let runner = FakeRunner(results: [
            ProcessResult(status: 0, stdout: "0.0\n", stderr: ""),
            ProcessResult(status: 1, stdout: "", stderr: "boom")
        ])
        let service = TrimService(
            ffmpegPath: "/fake/ffmpeg",
            ffprobePath: "/fake/ffprobe",
            runner: runner,
            trash: trash
        )

        XCTAssertThrowsError(try service.trimReplacing(file, range: TrimRange(start: 1, end: 2)))

        XCTAssertTrue(trash.trashedURLs.isEmpty)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "original")
    }
}

private final class FakeTrash: FileTrashing {
    private(set) var trashedURLs: [URL] = []

    func trash(_ url: URL) throws -> URL? {
        trashedURLs.append(url)
        try FileManager.default.removeItem(at: url)
        return nil
    }
}

private final class FakeRunner: ProcessRunning {
    struct Command {
        let executable: String
        let arguments: [String]
    }

    private var results: [ProcessResult]
    private(set) var commands: [Command] = []
    var onRun: ((String, [String]) -> ProcessResult)?

    init(results: [ProcessResult]) {
        self.results = results
    }

    func run(_ executable: String, arguments: [String]) throws -> ProcessResult {
        commands.append(Command(executable: executable, arguments: arguments))
        if let onRun {
            return onRun(executable, arguments)
        }
        guard !results.isEmpty else {
            return ProcessResult(status: 0, stdout: "", stderr: "")
        }
        return results.removeFirst()
    }
}
