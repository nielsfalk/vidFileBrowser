import Foundation

/// A macOS Finder tag color, as stored in the tag value after the `\n`.
enum TagColor: Int, CaseIterable, Sendable {
    case gray = 1
    case green = 2
    case purple = 3
    case blue = 4
    case yellow = 5
    case red = 6
    case orange = 7
}

/// A Finder tag with its optional color.
struct FileTag: Hashable, Sendable {
    let name: String
    let color: TagColor?

    init(name: String, color: TagColor? = nil) {
        self.name = name
        self.color = color
    }

    /// Parses a raw tag value such as `"Red\n6"`. Newer macOS versions append
    /// more numeric fields (`"Red\n6\n0"`), so every number is considered.
    init(rawValue: String) {
        let parts = rawValue
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
        name = parts.first ?? ""
        color = parts
            .dropFirst()
            .compactMap { Int($0) }
            .compactMap(TagColor.init(rawValue:))
            .first
    }

    /// The value Finder stores in `com.apple.metadata:_kMDItemUserTags`.
    var storedValue: String {
        guard let color else { return name }
        return "\(name)\n\(color.rawValue)"
    }
}
