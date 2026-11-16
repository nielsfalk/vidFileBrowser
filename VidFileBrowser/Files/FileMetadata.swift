import Foundation

/// Finder metadata that should survive a lossless edit.
struct FileMetadata {
    var tags: [FileTag]
    var creationDate: Date?
    var modificationDate: Date?

    static func capture(at url: URL) -> FileMetadata {
        let values = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
        return FileMetadata(
            tags: FinderTags.tags(for: url) ?? [],
            creationDate: values?.creationDate,
            modificationDate: values?.contentModificationDate
        )
    }

    /// Best effort: a failure to restore metadata must not undo the edit.
    func apply(to url: URL) {
        try? FinderTags.setTags(tags, for: url)

        var attributes: [FileAttributeKey: Any] = [:]
        if let creationDate {
            attributes[.creationDate] = creationDate
        }
        if let modificationDate {
            attributes[.modificationDate] = modificationDate
        }
        if !attributes.isEmpty {
            try? FileManager.default.setAttributes(attributes, ofItemAtPath: url.path)
        }
    }
}
