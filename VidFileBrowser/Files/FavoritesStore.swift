import Foundation
import Observation

struct FavoriteFolder: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var bookmark: Data
}

/// Favorite folders are stored as bookmarks so they survive renames and moves.
@Observable
final class FavoritesStore {
    private(set) var folders: [FavoriteFolder] = []

    private let defaults: UserDefaults
    private let storageKey = "favoriteFolders"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func add(_ url: URL) throws {
        let data = try url.bookmarkData(
            options: [],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        folders.append(FavoriteFolder(name: url.lastPathComponent, bookmark: data))
        save()
    }

    func remove(atOffsets offsets: IndexSet) {
        folders.remove(atOffsets: offsets)
        save()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        folders.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func url(for folder: FavoriteFolder) -> URL? {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: folder.bookmark,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }

        if isStale,
           let index = folders.firstIndex(where: { $0.id == folder.id }),
           let data = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil) {
            folders[index].bookmark = data
            save()
        }

        return url
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([FavoriteFolder].self, from: data)
        else {
            return
        }
        folders = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(folders) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
