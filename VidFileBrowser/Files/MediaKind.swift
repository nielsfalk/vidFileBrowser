import Foundation
import UniformTypeIdentifiers

enum MediaKind: String, Sendable {
    case video
    case image
    case other

    var isPlayable: Bool {
        self != .other
    }

    var title: String {
        switch self {
        case .video: "Video"
        case .image: "Image"
        case .other: "Not playable"
        }
    }
}

enum MediaKindDetector {
    /// Extensions mpv/ffmpeg and ImageIO handle even when macOS has no content type for them.
    static let videoExtensions: Set<String> = [
        "mp4", "m4v", "mov", "mkv", "webm", "avi", "flv", "wmv", "mpg", "mpeg",
        "m2ts", "mts", "ts", "ogv", "3gp", "divx"
    ]

    static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif", "gif", "tiff", "tif", "bmp", "webp", "avif"
    ]

    static func kind(for url: URL, contentType: UTType? = nil) -> MediaKind {
        if let contentType {
            if contentType.conforms(to: .movie) || contentType.conforms(to: .video) {
                return .video
            }
            if contentType.conforms(to: .image) {
                return .image
            }
        }

        let fileExtension = url.pathExtension.lowercased()
        if videoExtensions.contains(fileExtension) {
            return .video
        }
        if imageExtensions.contains(fileExtension) {
            return .image
        }
        return .other
    }
}
