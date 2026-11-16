import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "film.stack")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("VidFileBrowser")
                .font(.largeTitle.bold())
            Text("Project setup complete. Features follow in the next tasks.")
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(minWidth: 640, minHeight: 420)
    }
}
