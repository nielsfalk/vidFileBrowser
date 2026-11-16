import AppKit

enum KeyframePrompt {
    /// Asks whether the beginning should be re-encoded so the cut starts on a
    /// real keyframe. Returns true for "Add Keyframe".
    static func confirm(url: URL, range: TrimRange) -> Bool {
        let alert = NSAlert()
        alert.messageText = "No keyframe was found before the trim point"
        alert.informativeText = """
        \"\(url.lastPathComponent)\" has no keyframe before \(TimeFormatter.string(from: range.start)). \
        Add a keyframe at the beginning by re-encoding the trimmed part? \
        This makes the cut no longer lossless.
        """
        alert.addButton(withTitle: "Add Keyframe")
        alert.addButton(withTitle: "Cancel")

        return alert.runModal() == .alertFirstButtonReturn
    }
}
