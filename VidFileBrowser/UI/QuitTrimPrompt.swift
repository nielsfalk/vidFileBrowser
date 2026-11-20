import AppKit

enum QuitTrimPrompt {
    enum Choice {
        case wait
        case cancelTrims
        case stay
    }

    /// Asks what should happen to the trims that are still running when the
    /// app is about to quit.
    static func run(count: Int) -> Choice {
        let alert = NSAlert()
        if count == 1 {
            alert.messageText = "A trim is still running"
            alert.informativeText = "Wait for the trim to finish before quitting, or cancel it?"
        } else {
            alert.messageText = "\(count) trims are still running"
            alert.informativeText = "Wait for the trims to finish before quitting, or cancel them?"
        }
        alert.addButton(withTitle: count == 1 ? "Wait for Trim" : "Wait for Trims")
        alert.addButton(withTitle: "Cancel Trims")
        alert.addButton(withTitle: "Cancel")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            return .wait
        case .alertSecondButtonReturn:
            return .cancelTrims
        default:
            return .stay
        }
    }
}
