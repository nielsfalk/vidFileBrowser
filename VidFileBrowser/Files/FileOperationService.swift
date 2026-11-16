import Foundation

enum FileOperation {
    case copy
    case move
}

enum ConflictResolution: Equatable {
    case replace
    case keepBoth
    case skip
    case cancel
}

struct FileConflict: Equatable {
    let source: URL
    let destination: URL
}

/// Copies and moves files into a folder, asking the caller what to do when a
/// destination already exists.
struct FileOperationService {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func perform(
        _ operation: FileOperation,
        sources: [URL],
        into folder: URL,
        resolve: (FileConflict) -> ConflictResolution
    ) throws {
        for source in sources {
            try perform(operation, source: source, into: folder, resolve: resolve)
        }
    }

    func perform(
        _ operation: FileOperation,
        source: URL,
        into folder: URL,
        resolve: (FileConflict) -> ConflictResolution
    ) throws {
        var destination = folder.appendingPathComponent(source.lastPathComponent)
        if destination.standardizedFileURL == source.standardizedFileURL {
            return
        }

        if fileManager.fileExists(atPath: destination.path) {
            switch resolve(FileConflict(source: source, destination: destination)) {
            case .cancel:
                throw CancellationError()
            case .skip:
                return
            case .replace:
                try fileManager.removeItem(at: destination)
            case .keepBoth:
                destination = Self.uniqueDestination(for: destination, fileManager: fileManager)
            }
        }

        switch operation {
        case .copy:
            try fileManager.copyItem(at: source, to: destination)
        case .move:
            try fileManager.moveItem(at: source, to: destination)
        }
    }

    static func uniqueDestination(for url: URL, fileManager: FileManager = .default) -> URL {
        let directory = url.deletingLastPathComponent()
        let base = url.deletingPathExtension().lastPathComponent
        let fileExtension = url.pathExtension

        var index = 2
        while true {
            let name = fileExtension.isEmpty
                ? "\(base) \(index)"
                : "\(base) \(index).\(fileExtension)"
            let candidate = directory.appendingPathComponent(name)
            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
            index += 1
        }
    }
}
