import Foundation

struct TrimRange: Equatable {
    var start: Double
    var end: Double

    var duration: Double { max(0, end - start) }
}

enum TrimError: LocalizedError, Equatable {
    case ffmpegMissing
    case ffprobeMissing
    case invalidRange
    case noKeyframe
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .ffmpegMissing:
            "ffmpeg is not installed. Run brew install mpv ffmpeg."
        case .ffprobeMissing:
            "ffprobe is not installed. Run brew install mpv ffmpeg."
        case .invalidRange:
            "The trim range is empty."
        case .noKeyframe:
            "No keyframe was found before the trim point."
        case .failed(let message):
            message
        }
    }
}

protocol FileTrashing {
    /// Moves the file to the Trash and returns where it ended up, if known.
    func trash(_ url: URL) throws -> URL?
}

protocol TrimServicing {
    /// Trims and replaces the file, returning the URL of the trimmed file.
    @discardableResult
    func trimReplacing(_ url: URL, range: TrimRange) throws -> URL
}

struct FinderTrash: FileTrashing {
    func trash(_ url: URL) throws -> URL? {
        var resulting: NSURL?
        try FileManager.default.trashItem(at: url, resultingItemURL: &resulting)
        return resulting as URL?
    }
}

/// Cuts a video without re-encoding. The start is snapped back to the nearest
/// keyframe, so the cut stays lossless.
final class TrimService: TrimServicing {
    private let ffmpegPath: String?
    private let ffprobePath: String?
    private let runner: ProcessRunning
    private let trash: FileTrashing
    private let confirmReencode: ((URL, TrimRange) -> Bool)?

    init(
        ffmpegPath: String? = DependencyLocator.ffmpegPath(),
        ffprobePath: String? = DependencyLocator.ffprobePath(),
        runner: ProcessRunning = ProcessRunner(),
        trash: FileTrashing = FinderTrash(),
        confirmReencode: ((URL, TrimRange) -> Bool)? = nil
    ) {
        self.ffmpegPath = ffmpegPath
        self.ffprobePath = ffprobePath
        self.runner = runner
        self.trash = trash
        self.confirmReencode = confirmReencode
    }

    func keyframe(atOrBefore time: Double, in url: URL, searchWindow: Double = 10) throws -> Double {
        guard let ffprobePath else { throw TrimError.ffprobeMissing }

        let from = max(0, time - searchWindow)
        let to = time + 0.001
        let result = try runner.run(ffprobePath, arguments: [
            "-v", "error",
            "-select_streams", "v:0",
            "-skip_frame", "nokey",
            "-show_entries", "frame=pts_time",
            "-of", "csv=p=0",
            "-read_intervals", "\(Self.timeString(from))%\(Self.timeString(to))",
            url.path
        ])

        guard result.succeeded else {
            throw TrimError.failed(result.stderr.isEmpty ? "ffprobe failed." : result.stderr)
        }

        let times = Self.parseKeyframeTimes(result.stdout)
        guard let keyframe = Self.nearestKeyframe(times, atOrBefore: time) else {
            throw TrimError.noKeyframe
        }
        return keyframe
    }

    func trim(input: URL, range: TrimRange, output: URL) throws {
        guard range.duration > 0.05 else { throw TrimError.invalidRange }
        guard let ffmpegPath else { throw TrimError.ffmpegMissing }

        let start = try keyframe(atOrBefore: range.start, in: input)
        let arguments = Self.trimArguments(input: input, start: start, duration: range.end - start, output: output)

        let result = try runner.run(ffmpegPath, arguments: arguments)
        guard result.succeeded else {
            throw TrimError.failed(result.stderr.isEmpty ? "ffmpeg failed." : result.stderr)
        }
    }

    /// Cuts into a temporary file next to the original, renames it with the
    /// `_t` suffix, moves the original to the Trash and returns the new URL.
    @discardableResult
    func trimReplacing(_ url: URL, range: TrimRange) throws -> URL {
        guard range.duration > 0.05 else { throw TrimError.invalidRange }

        let directory = url.deletingLastPathComponent()
        let base = url.deletingPathExtension().lastPathComponent
        let fileExtension = url.pathExtension
        let tempName = ".\(base)-trim-\(UUID().uuidString).\(fileExtension)"
        let temp = directory.appendingPathComponent(tempName)

        defer { try? FileManager.default.removeItem(at: temp) }

        do {
            try trim(input: url, range: range, output: temp)
        } catch TrimError.noKeyframe {
            guard askForReencode(url: url, range: range) else {
                throw TrimError.noKeyframe
            }
            try trimReencoding(input: url, range: range, output: temp)
        }

        let trimmedName = TrimNaming.trimmedName(for: url.lastPathComponent)
        var destination = directory.appendingPathComponent(trimmedName)
        if destination.standardizedFileURL != url.standardizedFileURL,
           FileManager.default.fileExists(atPath: destination.path) {
            destination = FileOperationService.uniqueDestination(for: destination)
        }

        let metadata = FileMetadata.capture(at: url)
        let trashed = try trash.trash(url)
        do {
            try FileManager.default.moveItem(at: temp, to: destination)
            metadata.apply(to: destination)
        } catch {
            if let trashed {
                try? FileManager.default.moveItem(at: trashed, to: url)
            }
            throw error
        }
        return destination
    }

    /// The confirmation is UI, so it must run on the main thread even though
    /// trimming itself happens in the background.
    private func askForReencode(url: URL, range: TrimRange) -> Bool {
        guard let confirmReencode else { return false }
        if Thread.isMainThread {
            return confirmReencode(url, range)
        }

        var confirmed = false
        DispatchQueue.main.sync {
            confirmed = confirmReencode(url, range)
        }
        return confirmed
    }

    /// Accurate cut that re-encodes, so the trimmed file starts with a keyframe.
    func trimReencoding(input: URL, range: TrimRange, output: URL) throws {
        guard range.duration > 0.05 else { throw TrimError.invalidRange }
        guard let ffmpegPath else { throw TrimError.ffmpegMissing }

        let result = try runner.run(
            ffmpegPath,
            arguments: Self.reencodeArguments(input: input, range: range, output: output)
        )
        guard result.succeeded else {
            throw TrimError.failed(result.stderr.isEmpty ? "ffmpeg failed." : result.stderr)
        }
    }

    static func reencodeArguments(input: URL, range: TrimRange, output: URL) -> [String] {
        [
            "-hide_banner",
            "-loglevel", "error",
            "-y",
            "-ss", timeString(range.start),
            "-i", input.path,
            "-t", timeString(range.duration),
            "-map", "0:v:0",
            "-map", "0:a?",
            "-c:v", "libx264",
            "-preset", "veryfast",
            "-crf", "18",
            "-c:a", "copy",
            "-movflags", "+faststart",
            output.path
        ]
    }

    static func trimArguments(input: URL, start: Double, duration: Double, output: URL) -> [String] {
        [
            "-hide_banner",
            "-loglevel", "error",
            "-y",
            "-ss", timeString(start),
            "-i", input.path,
            "-t", timeString(duration),
            "-map", "0",
            "-c", "copy",
            "-avoid_negative_ts", "make_zero",
            output.path
        ]
    }

    static func parseKeyframeTimes(_ output: String) -> [Double] {
        output
            .split(whereSeparator: \.isNewline)
            .flatMap { $0.split(separator: ",") }
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
    }

    static func nearestKeyframe(_ times: [Double], atOrBefore time: Double) -> Double? {
        times
            .filter { $0 <= time + 0.001 }
            .max()
    }

    static func timeString(_ seconds: Double) -> String {
        String(format: "%.3f", max(0, seconds))
    }
}
