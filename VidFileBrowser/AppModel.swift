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
    private let pasteboard: NSPasteboard
    private let trashService: FileTrashing
    private let fileOperationService = FileOperationService()
    private let conflictResolver: ((FileConflict) -> ConflictResolution)?
    private var applyToAllResolution: ConflictResolution?
    private var cutURLs: [URL] = []
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

    var selectedItems: [FileItem] {
        items.filter { selection.contains($0.id) }
    }

    var playerInfoState: PlayerInfoState? {
        let selected = selectedItems
        guard !selected.isEmpty else { return .noSelection }
        guard selected.count == 1 else { return .multiple(selected.count) }
        guard let item = selected.first else { return .noSelection }
        if item.isDirectory { return .folder(item.name) }
        if !item.kind.isPlayable { return .notMedia(item.name) }
        return nil
    }

    init(
        loader: DirectoryLoader = DirectoryLoader(),
        settings: AppSettings = AppSettings(),
        player: PlayerController? = nil,
        trimService: TrimServicing = TrimService(confirmReencode: KeyframePrompt.confirm),
        favorites: FavoritesStore = FavoritesStore(),
        pasteboard: NSPasteboard = .general,
        trash: FileTrashing = FinderTrash(),
        conflictResolver: ((FileConflict) -> ConflictResolution)? = nil,
        restoreLastFolder: Bool = true
    ) {
        self.loader = loader
        self.settings = settings
        self.player = player ?? PlayerController(player: PlayerFactory.make())
        self.trimService = trimService
        self.favorites = favorites
        self.pasteboard = pasteboard
        self.trashService = trash
        self.conflictResolver = conflictResolver
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

    func selectPrevious() {
        moveSelection(by: -1)
    }

    func selectNext() {
        moveSelection(by: 1)
    }

    /// Handles playback keys that are also useful while the file browser is
    /// hidden in full screen.
    func handle(_ shortcut: BrowserShortcut) {
        switch shortcut {
        case .playPause:
            if player.currentURL != nil || image != nil {
                player.togglePlayPause()
            }
        case .skipBackward10:
            player.skip(by: -10)
        case .skipForward10:
            player.skip(by: 10)
        case .skipBackward30:
            player.skip(by: -30)
        case .skipForward30:
            player.skip(by: 30)
        case .trimLeft:
            trimLeft()
        case .trimRight:
            trimRight()
        case .toggleFullScreen, .exitFullScreen:
            break
        }
    }

    private func moveSelection(by offset: Int) {
        guard !items.isEmpty else { return }

        let currentIndex = selectedItem.flatMap { item in
            items.firstIndex { $0.id == item.id }
        } ?? -1
        let nextIndex = min(max(currentIndex + offset, 0), items.count - 1)

        selection = [items[nextIndex].id]
        selectionDidChange()
    }

    func playSelectedItem() {
        let selected = selectedItems
        guard selected.count == 1, let item = selected.first, !item.isDirectory else {
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
        move([item], to: folder)
    }

    @discardableResult
    func move(_ items: [FileItem], to folder: URL) -> Bool {
        guard !items.isEmpty else { return false }

        applyToAllResolution = nil
        defer { applyToAllResolution = nil }

        do {
            let results = try fileOperationService.perform(
                .move,
                sources: items.map(\.url),
                into: folder,
                resolve: resolveConflict(_:)
            )
            errorMessage = nil
            let moved = Set(results.compactMap { $0.destination == nil ? nil : $0.source })
            handleRemoved(moved)
            return !moved.isEmpty
        } catch is CancellationError {
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Copies files dropped from Finder into the current folder.
    @discardableResult
    func importFiles(_ urls: [URL]) -> Bool {
        guard let directory else { return false }

        let files = urls.filter { url in
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
            return exists && !isDirectory.boolValue
        }
        guard !files.isEmpty else { return false }

        applyToAllResolution = nil
        defer { applyToAllResolution = nil }

        do {
            try fileOperationService.perform(
                .copy,
                sources: files,
                into: directory,
                resolve: resolveConflict(_:)
            )
            errorMessage = nil
            reload()
            return true
        } catch is CancellationError {
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func resolveConflict(_ conflict: FileConflict) -> ConflictResolution {
        if let conflictResolver {
            return conflictResolver(conflict)
        }
        if let applyToAllResolution {
            return applyToAllResolution
        }

        let result = ConflictDialog.run(conflict)
        if result.applyToAll, result.resolution != .cancel {
            applyToAllResolution = result.resolution
        }
        return result.resolution
    }

    // MARK: - Renaming

    @discardableResult
    func rename(_ item: FileItem, to newName: String) -> Bool {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !name.contains("/"), name != item.name else { return false }

        let target = item.url.deletingLastPathComponent().appendingPathComponent(name)
        guard !FileManager.default.fileExists(atPath: target.path) else {
            errorMessage = "An item named \"\(name)\" already exists."
            return false
        }

        do {
            try FileManager.default.moveItem(at: item.url, to: target)
        } catch {
            errorMessage = error.localizedDescription
            return false
        }

        errorMessage = nil
        let wasPlaying = player.currentURL == item.url
        reload()

        if let renamed = items.first(where: { $0.url == target }) {
            selection = [renamed.id]
            if wasPlaying {
                player.load(renamed.url, autoplay: true)
            }
        }
        return true
    }

    // MARK: - Finder integration

    func revealInFinder(_ items: [FileItem]) {
        guard !items.isEmpty else { return }
        NSWorkspace.shared.activateFileViewerSelecting(items.map(\.url))
    }

    func copyPaths(of items: [FileItem]) {
        guard !items.isEmpty else { return }
        pasteboard.clearContents()
        pasteboard.setString(items.map(\.url.path).joined(separator: "\n"), forType: .string)
    }

    // MARK: - Clipboard

    func copySelection() {
        let urls = selectedItems.map(\.url)
        guard !urls.isEmpty else { return }
        FilePasteboard.write(urls, to: pasteboard)
        cutURLs = []
    }

    func cutSelection() {
        let urls = selectedItems.map(\.url)
        guard !urls.isEmpty else { return }
        FilePasteboard.write(urls, to: pasteboard)
        cutURLs = urls
    }

    @discardableResult
    func paste() -> Bool {
        guard let directory else { return false }
        let urls = FilePasteboard.readURLs(from: pasteboard)
        guard !urls.isEmpty else { return false }

        let isCut = !cutURLs.isEmpty && urls.allSatisfy { cutURLs.contains($0) }
        let operation: FileOperation = isCut ? .move : .copy

        applyToAllResolution = nil
        defer { applyToAllResolution = nil }

        do {
            let results = try fileOperationService.perform(
                operation,
                sources: urls,
                into: directory,
                resolve: resolveConflict(_:)
            )
            cutURLs = []
            errorMessage = nil
            reload()

            let pasted = Set<FileItem.ID>(results.compactMap { result -> FileItem.ID? in
                guard let destination = result.destination else { return nil }
                return items.first { $0.url == destination }?.id
            })
            if !pasted.isEmpty {
                selection = pasted
                selectionDidChange()
            }
            return true
        } catch is CancellationError {
            cutURLs = []
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Trash

    func moveToTrash(_ items: [FileItem]) {
        guard !items.isEmpty else { return }

        var removed: Set<URL> = []
        for item in items {
            do {
                _ = try trashService.trash(item.url)
                removed.insert(item.url)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        handleRemoved(removed)
    }

    /// Reloads and selects the file that follows the removed ones, so playback
    /// continues without an extra click.
    private func handleRemoved(_ removed: Set<URL>) {
        guard !removed.isEmpty else { return }

        let index = items.firstIndex { removed.contains($0.url) } ?? 0
        reload()

        guard !items.isEmpty else {
            selection = []
            player.stop()
            return
        }

        let next = items[min(index, items.count - 1)]
        selection = [next.id]
        selectionDidChange()
    }

    // MARK: - Tags

    func toggleTag(_ color: TagColor, on item: FileItem) {
        toggleTag(color, on: [item])
    }

    func toggleTag(_ color: TagColor, on items: [FileItem]) {
        guard !items.isEmpty else { return }

        let allHaveColor = items.allSatisfy { $0.tagColors.contains(color) }
        for item in items where item.tagColors.contains(color) == allHaveColor {
            do {
                try tagService.toggle(color: color, on: item.url)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        reload()
    }

    func removeAllTags(from item: FileItem) {
        removeAllTags(from: [item])
    }

    func removeAllTags(from items: [FileItem]) {
        guard !items.isEmpty else { return }

        for item in items {
            do {
                try tagService.removeAll(from: item.url)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        reload()
    }

    private func performTrim(url: URL, range: TrimRange) {
        guard range.duration > 0.05, !isTrimming else { return }

        isTrimming = true
        trimError = nil
        let service = trimService

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let trimmedURL = try service.trimReplacing(url, range: range)
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.isTrimming = false
                    self.reload()
                    if let item = self.items.first(where: { $0.url == trimmedURL }) {
                        self.selection = [item.id]
                        self.player.load(trimmedURL, autoplay: true)
                    }
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
