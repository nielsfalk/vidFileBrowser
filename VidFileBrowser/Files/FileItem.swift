import Foundation

enum SortProperty: String, CaseIterable, Identifiable, Sendable {
    case name
    case date
    case label
    case size

    var id: String { rawValue }

    var title: String {
        switch self {
        case .name: "Name"
        case .date: "Date"
        case .label: "Label"
        case .size: "Size"
        }
    }

    var columnTitle: String {
        switch self {
        case .name: "Name"
        case .date: "Date Modified"
        case .label: "Label"
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

    /// The Finder label index, 0 for no label.
    var labelNumber: Int {
        tagColors.first?.rawValue ?? 0
    }

    func sortValueText(for property: SortProperty) -> String {
        switch property {
        case .name:
            return ""
        case .date:
            return modificationDate?.formatted(date: .abbreviated, time: .shortened) ?? "—"
        case .label:
            let names = tags.map(\.name)
            return names.isEmpty ? "—" : names.joined(separator: ", ")
        case .size:
            guard let size else { return "—" }
            return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        }
    }
}
