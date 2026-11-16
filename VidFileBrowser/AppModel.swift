import AppKit
import Foundation
import Observation

@Observable
final class AppModel {
    private let loader: DirectoryLoader
    private let settings: AppSettings
    private let watcher = DirectoryWatcher()
    let player: PlayerController

    private(set) var directory: URL?
    private(set) var items: [FileItem] = []
    private(set) var errorMessage: String?
    private(set) var image: NSImage?
    private(set) var imageURL: URL?
    var selection: Set<FileItem.ID> = []

    var sortProperty: SortProperty {
        didSet {
            settings.sortProperty = sortProperty
            resort()
        }
    }
    var sortAscending: Bool {
        didSet {
            settings.sortAscending = sortAscending
            resort()
        }
    }

    private var allItems: [FileItem] = []

    var selectedItem: FileItem? {
        items.first { selection.contains($0.id) }
    }

    init(
        loader: DirectoryLoader = DirectoryLoader(),
        settings: AppSettings = AppSettings(),
        player: PlayerController? = nil,
        restoreLastFolder: Bool = true
    ) {
        self.loader = loader
        self.settings = settings
        self.player = player ?? PlayerController(player: PlayerFactory.make())
        sortProperty = settings.sortProperty
        sortAscending = settings.sortAscending

        if restoreLastFolder, let path = settings.lastFolderPath {
            open(URL(fileURLWithPath: path, isDirectory: true))
        }
    }

    func open(_ url: URL) {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            return
        }

        directory = url
        settings.lastFolderPath = url.path
        selection = []
        reload()
        watcher.watch(url) { [weak self] in
            self?.reload()
        }
    }

    func reload() {
        guard let directory else {
            allItems = []
            items = []
            return
        }

        do {
            allItems = try loader.loadItems(in: directory)
            errorMessage = nil
            resort()
        } catch {
            allItems = []
            items = []
            errorMessage = error.localizedDescription
        }
    }

    func activate(_ item: FileItem) {
        if item.isDirectory {
            open(item.url)
        }
    }

    func selectionDidChange() {
        playSelectedItem()
    }

    func playSelectedItem() {
        guard let item = selectedItem, !item.isDirectory else {
            clearMedia()
            return
        }

        switch item.kind {
        case .video:
            image = nil
            imageURL = nil
            guard player.currentURL != item.url else { return }
            player.load(item.url, autoplay: true)
        case .image:
            player.stop()
            guard imageURL != item.url else { return }
            imageURL = item.url
            image = ImageLoader.image(at: item.url)
        case .other:
            clearMedia()
        }
    }

    private func clearMedia() {
        player.stop()
        image = nil
        imageURL = nil
    }

    private func resort() {
        items = FileSorter.sorted(allItems, by: sortProperty, ascending: sortAscending)
        let visible = Set(items.map(\.id))
        selection = selection.intersection(visible)
    }
}
