import Foundation

/// Reads and writes Finder tags on files.
struct FinderTagService {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func tags(of url: URL) -> [FileTag] {
        FinderTags.tags(for: url) ?? []
    }

    func setTags(_ tags: [FileTag], on url: URL) throws {
        try FinderTags.setTags(tags, for: url)
    }

    func toggle(color: TagColor, on url: URL) throws {
        var tags = tags(of: url)
        if let index = tags.firstIndex(where: { $0.color == color }) {
            tags.remove(at: index)
        } else {
            tags.append(FileTag(name: Self.defaultName(for: color), color: color))
        }
        try setTags(tags, on: url)
    }

    func removeAll(from url: URL) throws {
        try setTags([], on: url)
    }

    static func defaultName(for color: TagColor) -> String {
        switch color {
        case .gray: "Gray"
        case .green: "Green"
        case .purple: "Purple"
        case .blue: "Blue"
        case .yellow: "Yellow"
        case .red: "Red"
        case .orange: "Orange"
        }
    }
}
