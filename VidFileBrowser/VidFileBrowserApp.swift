import SwiftUI

@main
struct VidFileBrowserApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
        .defaultSize(width: 1400, height: 900)
        .commands {
            PlaybackCommands(model: model)
        }
    }
}
