import Foundation

/// What the player area shows instead of media.
enum PlayerInfoState: Equatable {
    case noSelection
    case multiple(Int)
    case folder(String)
    case notMedia(String)

    var title: String {
        switch self {
        case .noSelection:
            "No file selected"
        case .multiple(let count):
            "^[\(count) file](inflect: true) selected"
        case .folder(let name):
            "“\(name)” is a folder"
        case .notMedia(let name):
            "“\(name)” is not a media file"
        }
    }

    var subtitle: String {
        switch self {
        case .noSelection:
            "Choose a video or image to start playing."
        case .multiple:
            "Select a single file to play it."
        case .folder:
            "Press Enter or double-click to open it."
        case .notMedia:
            "Only videos and images can be played."
        }
    }

    var systemImage: String {
        switch self {
        case .noSelection:
            "play.rectangle"
        case .multiple:
            "doc.on.doc"
        case .folder:
            "folder"
        case .notMedia:
            "doc"
        }
    }
}
