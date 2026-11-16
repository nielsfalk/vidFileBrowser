import Foundation

/// Paths to the external tools the app needs at runtime.
struct Dependencies: Equatable {
    var libmpvPath: String?
    var ffmpegPath: String?

    var isSatisfied: Bool {
        libmpvPath != nil && ffmpegPath != nil
    }

    static let installCommand = "brew install mpv ffmpeg"
}

enum DependencyLocator {
    /// Homebrew prefixes: Apple Silicon first, then Intel.
    static let homebrewPrefixes = ["/opt/homebrew", "/usr/local"]

    static func locate(prefixes: [String] = homebrewPrefixes) -> Dependencies {
        Dependencies(
            libmpvPath: libmpv(in: prefixes),
            ffmpegPath: ffmpeg(in: prefixes)
        )
    }

    static func ffmpegPath() -> String? {
        ffmpeg(in: homebrewPrefixes)
    }

    static func ffprobePath() -> String? {
        let candidates = homebrewPrefixes.map { "\($0)/bin/ffprobe" }
            + ["/usr/bin/ffprobe", "/usr/local/bin/ffprobe"]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private static func libmpv(in prefixes: [String]) -> String? {
        prefixes
            .map { "\($0)/lib/libmpv.dylib" }
            .first { FileManager.default.fileExists(atPath: $0) }
    }

    static func ffmpeg(in prefixes: [String]) -> String? {
        prefixes
            .map { "\($0)/bin/ffmpeg" }
            .first { FileManager.default.isExecutableFile(atPath: $0) }
    }
}
