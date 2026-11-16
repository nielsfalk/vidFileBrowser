import SwiftUI

@main
struct VidFileBrowserApp: App {
    @State private var favorites: FavoritesStore
    @State private var model: AppModel

    init() {
        let favorites = FavoritesStore()
        _favorites = State(initialValue: favorites)
        _model = State(initialValue: AppModel(favorites: favorites))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
        .defaultSize(width: 1400, height: 900)
        .commands {
            PlaybackCommands(model: model)
        }

        Settings {
            FavoritesSettingsView(store: favorites)
        }
    }
}
