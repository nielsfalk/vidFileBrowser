import AppKit

/// Keys handled by the file browser so they work even though the table view
/// would otherwise use them for type-select.
enum BrowserShortcut: Equatable {
    case playPause
    case skipBackward40
    case skipForward40
    case skipBackward10
    case skipForward10
    case skipBackward30
    case skipForward30
    case trimLeft
    case trimRight
    case toggleFullScreen
    case exitFullScreen

    init?(event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags.isEmpty else { return nil }

        switch event.keyCode {
        case 49:
            self = .playPause
        case 126:
            self = .skipBackward40
        case 125:
            self = .skipForward40
        case 123:
            self = .skipBackward10
        case 124:
            self = .skipForward10
        case 53:
            self = .exitFullScreen
        default:
            guard let character = event.charactersIgnoringModifiers?.lowercased() else { return nil }
            switch character {
            case "f":
                self = .toggleFullScreen
            case "n":
                self = .trimLeft
            case "m":
                self = .trimRight
            case ",":
                self = .skipBackward30
            case ".":
                self = .skipForward30
            default:
                return nil
            }
        }
    }
}
