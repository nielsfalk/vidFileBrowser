import AppKit

struct ConflictDialogResult {
    let resolution: ConflictResolution
    let applyToAll: Bool
}

enum ConflictDialog {
    static func run(_ conflict: FileConflict) -> ConflictDialogResult {
        let alert = NSAlert()
        alert.messageText = "An item named “\(conflict.destination.lastPathComponent)” already exists"
        alert.informativeText = "Do you want to replace it with “\(conflict.source.lastPathComponent)”?"

        alert.addButton(withTitle: "Keep Both")
        alert.addButton(withTitle: "Replace")
        alert.addButton(withTitle: "Skip")
        alert.addButton(withTitle: "Cancel")

        let checkbox = NSButton(checkboxWithTitle: "Apply to all", target: nil, action: nil)
        alert.accessoryView = checkbox

        let resolution: ConflictResolution
        switch alert.runModal() {
        case .alertFirstButtonReturn: resolution = .keepBoth
        case .alertSecondButtonReturn: resolution = .replace
        case .alertThirdButtonReturn: resolution = .skip
        default: resolution = .cancel
        }

        return ConflictDialogResult(resolution: resolution, applyToAll: checkbox.state == .on)
    }
}
