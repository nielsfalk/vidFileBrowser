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
struct FileOperationResult {
    let source: URL
    /// nil when the file was skipped.
    let destination: URL?
}

struct FileOperationService {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    @discardableResult
    func perform(
        _ operation: FileOperation,
        sources: [URL],
        into folder: URL,
        resolve: (FileConflict) -> ConflictResolution
    ) throws -> [FileOperationResult] {
        var results: [FileOperationResult] = []
        for source in sources {
            results.append(try perform(operation, source: source, into: folder, resolve: resolve))
        }
        return results
    }

    @discardableResult
    func perform(
        _ operation: FileOperation,
        source: URL,
        into folder: URL,
        resolve: (FileConflict) -> ConflictResolution
    ) throws -> FileOperationResult {
        let destination = folder.appendingPathComponent(source.lastPathComponent)
        let isSameFile = destination.standardizedFileURL == source.standardizedFileURL
        if isSameFile, operation == .move {
            return FileOperationResult(source: source, destination: nil)
        }

        var target = destination
        if fileManager.fileExists(atPath: target.path) {
            var resolution = resolve(FileConflict(source: source, destination: target))
            // Copying a file onto itself must never delete the source.
            if isSameFile, resolution == .replace {
                resolution = .keepBoth
            }

            switch resolution {
            case .cancel:
                throw CancellationError()
            case .skip:
                return FileOperationResult(source: source, destination: nil)
            case .replace:
                try fileManager.removeItem(at: target)
            case .keepBoth:
                target = Self.uniqueDestination(for: target, fileManager: fileManager)
            }
        }

        switch operation {
        case .copy:
            try fileManager.copyItem(at: source, to: target)
        case .move:
            try fileManager.moveItem(at: source, to: target)
        }

        return FileOperationResult(source: source, destination: target)
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
