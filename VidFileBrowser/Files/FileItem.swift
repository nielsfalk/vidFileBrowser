import Foundation

enum SortProperty: String, CaseIterable, Identifiable, Sendable {
    case name
    case date
    case tag
    case size

    var id: String { rawValue }

    var title: String {
        switch self {
        case .name: "Name"
        case .date: "Date"
        case .tag: "Tags"
        case .size: "Size"
        }
    }

    var columnTitle: String {
        switch self {
        case .name: "Name"
        case .date: "Date Modified"
        case .tag: "Tags"
        case .size: "Size"
        }
    }
}

/// One entry in the file browser.
struct FileItem: Identifiable, Hashable, Sendable {
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64?
    let modificationDate: Date?
    let tags: [FileTag]
    let kind: MediaKind

    var id: URL { url }

    var tagColors: [TagColor] {
        tags.compactMap(\.color)
    }

    /// Tag names in a stable order, used to sort by the whole combination of
    /// tags rather than just the first one.
    var sortedTagNames: [String] {
        tags.map(\.name).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    func sortValueText(for property: SortProperty) -> String {
        switch property {
        case .name:
            return ""
        case .date:
            return modificationDate?.formatted(date: .abbreviated, time: .shortened) ?? "—"
        case .tag:
            let names = tags.map(\.name)
            return names.isEmpty ? "—" : names.joined(separator: ", ")
        case .size:
            guard let size else { return "—" }
            return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        }
    }
}
