import SwiftUI

struct ContentView: View {
    private let dependencies: Dependencies

    init(dependencies: Dependencies = DependencyLocator.locate()) {
        self.dependencies = dependencies
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "film.stack")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("VidFileBrowser")
                .font(.largeTitle.bold())

            if dependencies.isSatisfied {
                Label("mpv and ffmpeg found", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                missingDependencies
            }
        }
        .padding(32)
        .frame(minWidth: 640, minHeight: 420)
    }

    private var missingDependencies: some View {
        VStack(spacing: 8) {
            Label("Missing dependencies", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Text("VidFileBrowser needs mpv for playback and ffmpeg for trimming.")
            Text(missingTools)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(Dependencies.installCommand)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
            Text("Install them, then restart the app.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var missingTools: String {
        var missing: [String] = []
        if dependencies.libmpvPath == nil {
            missing.append("libmpv")
        }
        if dependencies.ffmpegPath == nil {
            missing.append("ffmpeg")
        }
        return "Missing: " + missing.joined(separator: ", ")
    }
}

#Preview {
    ContentView(dependencies: Dependencies(libmpvPath: nil, ffmpegPath: nil))
}
