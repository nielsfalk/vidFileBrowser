import Foundation

struct ProcessResult {
    let status: Int32
    let stdout: String
    let stderr: String

    var succeeded: Bool { status == 0 }
}

protocol ProcessRunning {
    func run(_ executable: String, arguments: [String]) throws -> ProcessResult
}

struct ProcessRunner: ProcessRunning {
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
        process.waitUntilExit()

        let output = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorOutput = stderr.fileHandleForReading.readDataToEndOfFile()

        return ProcessResult(
            status: process.terminationStatus,
            stdout: String(decoding: output, as: UTF8.self),
            stderr: String(decoding: errorOutput, as: UTF8.self)
        )
    }
}
