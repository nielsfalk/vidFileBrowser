import Foundation

struct DirectoryLoader {
    private let keys: [URLResourceKey] = [
        .isDirectoryKey,
        .fileSizeKey,
        .contentModificationDateKey,
        .tagNamesKey,
        .contentTypeKey
    ]

    func loadItems(in directory: URL) throws -> [FileItem] {
        let urls = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: keys,
            options: []
        )
        return urls.compactMap { makeItem(for: $0) }
    }

    private func makeItem(for url: URL) -> FileItem? {
        let values = try? url.resourceValues(forKeys: Set(keys))
        let isDirectory = values?.isDirectory ?? false
        let rawTags = values?.tagNames ?? []
        let tags = FinderTags.tags(for: url) ?? rawTags.map(FileTag.init(rawValue:))
        let kind = isDirectory ? .other : MediaKindDetector.kind(for: url, contentType: values?.contentType)

        return FileItem(
            url: url,
            name: url.lastPathComponent,
            isDirectory: isDirectory,
            size: isDirectory ? nil : values?.fileSize.map { Int64($0) },
            modificationDate: values?.contentModificationDate,
            tags: tags,
            kind: kind
        )
    }
}
