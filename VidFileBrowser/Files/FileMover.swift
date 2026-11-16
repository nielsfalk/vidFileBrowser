import Foundation

enum MoveError: LocalizedError, Equatable {
    case notADirectory(String)
    case destinationExists(String)

    var errorDescription: String? {
        switch self {
        case .notADirectory(let name):
            "\"\(name)\" is not a folder."
        case .destinationExists(let name):
            "A file named \"\(name)\" already exists in the target folder."
        }
    }
}

enum FileMover {
    static func destination(for url: URL, in folder: URL) -> URL {
        folder.appendingPathComponent(url.lastPathComponent)
    }

    static func move(_ url: URL, into folder: URL) throws {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            throw MoveError.notADirectory(folder.lastPathComponent)
        }

        let target = destination(for: url, in: folder)
        if target.standardizedFileURL == url.standardizedFileURL {
            return
        }

        guard !FileManager.default.fileExists(atPath: target.path) else {
            throw MoveError.destinationExists(url.lastPathComponent)
        }

        do {
            try FileManager.default.moveItem(at: url, to: target)
        } catch {
            throw error
        }
    }
}
