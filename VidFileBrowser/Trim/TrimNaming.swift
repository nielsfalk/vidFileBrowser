import Foundation

enum TrimNaming {
    /// Adds `_t` to the base name (before the first dot) unless it is already
    /// there, e.g. `clip.mov` becomes `clip_t.mov`.
    static func trimmedName(for name: String) -> String {
        guard !name.isEmpty else { return name }

        let searchStart = name.hasPrefix(".") ? name.index(after: name.startIndex) : name.startIndex
        let dotIndex = name[searchStart...].firstIndex(of: ".")

        let base = dotIndex.map { String(name[..<$0]) } ?? name
        guard !base.hasSuffix("_t") else { return name }

        let rest = dotIndex.map { String(name[$0...]) } ?? ""
        return base + "_t" + rest
    }
}
