import Foundation
import Observation

@Observable
final class AppModel {
    private let loader: DirectoryLoader

    private(set) var directory: URL?
    private(set) var items: [FileItem] = []
    private(set) var errorMessage: String?
    var selection: Set<FileItem.ID> = []

    var selectedItem: FileItem? {
        items.first { selection.contains($0.id) }
    }

    init(loader: DirectoryLoader = DirectoryLoader()) {
        self.loader = loader
    }

    func open(_ url: URL) {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            return
        }

        directory = url
        selection = []
        reload()
    }

    func reload() {
        guard let directory else {
            items = []
            return
        }

        do {
            items = try loader.loadItems(in: directory)
            errorMessage = nil
        } catch {
            items = []
            errorMessage = error.localizedDescription
        }
    }

    func activate(_ item: FileItem) {
        if item.isDirectory {
            open(item.url)
        }
    }
}
