import AppKit
import Foundation
import Observation

@Observable
final class AppModel {
    private let loader: DirectoryLoader
    private let settings: AppSettings
    private let watcher = DirectoryWatcher()
    private let trimService: TrimServicing
    private let tagService = FinderTagService()
    let favorites: FavoritesStore
    let player: PlayerController

    private(set) var directory: URL?
    private(set) var items: [FileItem] = []
    private(set) var errorMessage: String?
    private(set) var image: NSImage?
    private(set) var imageURL: URL?
    private(set) var isTrimming = false
    private(set) var trimError: String?
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
        trimService: TrimServicing = TrimService(),
        favorites: FavoritesStore = FavoritesStore(),
        restoreLastFolder: Bool = true
    ) {
        self.loader = loader
        self.settings = settings
        self.player = player ?? PlayerController(player: PlayerFactory.make())
        self.trimService = trimService
        self.favorites = favorites
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

    // MARK: - Trimming

    func trimLeft() {
        guard let url = player.currentURL, player.duration > 0 else { return }
        performTrim(url: url, range: TrimRange(start: player.currentTime, end: player.duration))
    }

    func trimRight() {
        guard let url = player.currentURL, player.duration > 0 else { return }
        performTrim(url: url, range: TrimRange(start: 0, end: player.currentTime))
    }

    func dismissTrimError() {
        trimError = nil
    }

    // MARK: - Moving files

    @discardableResult
    func move(_ item: FileItem, to folder: URL) -> Bool {
        do {
            try FileMover.move(item.url, into: folder)
            errorMessage = nil
            reload()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Tags

    func toggleTag(_ color: TagColor, on item: FileItem) {
        do {
            try tagService.toggle(color: color, on: item.url)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeAllTags(from item: FileItem) {
        do {
            try tagService.removeAll(from: item.url)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func performTrim(url: URL, range: TrimRange) {
        guard range.duration > 0.05, !isTrimming else { return }

        isTrimming = true
        trimError = nil
        let service = trimService

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try service.trimReplacing(url, range: range)
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.isTrimming = false
                    self.reload()
                    if let item = self.items.first(where: { $0.url == url }) {
                        self.selection = [item.id]
                    }
                    self.player.load(url, autoplay: true)
                }
            } catch {
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.isTrimming = false
                    self.trimError = error.localizedDescription
                }
            }
        }
    }

    private func resort() {
        items = FileSorter.sorted(allItems, by: sortProperty, ascending: sortAscending)
        let visible = Set(items.map(\.id))
        selection = selection.intersection(visible)
    }
}
