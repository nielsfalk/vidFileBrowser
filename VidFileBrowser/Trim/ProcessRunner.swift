import Foundation

struct ProcessResult {
    let status: Int32
    let stdout: String
    let stderr: String

    var succeeded: Bool { status == 0 }
}

protocol ProcessRunning {
    func run(_ executable: String, arguments: [String]) throws -> ProcessResult

    /// Stops every process that is currently running through this runner.
    func cancelAll()
}

extension ProcessRunning {
    func cancelAll() {}
}

struct ProcessRunner: ProcessRunning {
    private static let lock = NSLock()
    private static var activeProcesses: [Process] = []

    func run(_ executable: String, arguments: [String]) throws -> ProcessResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        process.standardInput = FileHandle.nullDevice

        try process.run()
        Self.track(process)
        defer { Self.untrack(process) }
        process.waitUntilExit()

        let output = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorOutput = stderr.fileHandleForReading.readDataToEndOfFile()

        return ProcessResult(
            status: process.terminationStatus,
            stdout: String(decoding: output, as: UTF8.self),
            stderr: String(decoding: errorOutput, as: UTF8.self)
        )
    }

    func cancelAll() {
        Self.lock.lock()
        let processes = Self.activeProcesses
        Self.lock.unlock()

        for process in processes where process.isRunning {
            process.terminate()
        }
    }

    private static func track(_ process: Process) {
        lock.lock()
        activeProcesses.append(process)
        lock.unlock()
    }

    private static func untrack(_ process: Process) {
        lock.lock()
        activeProcesses.removeAll { $0 === process }
        lock.unlock()
    }
}
