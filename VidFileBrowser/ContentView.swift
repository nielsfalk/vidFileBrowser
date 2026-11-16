import SwiftUI

struct ContentView: View {
    private let dependencies: Dependencies
    @State private var browserWidth: CGFloat = 440

    init(dependencies: Dependencies = DependencyLocator.locate()) {
        self.dependencies = dependencies
    }

    var body: some View {
        VStack(spacing: 0) {
            if !dependencies.isSatisfied {
                dependencyBanner
            }
            breadcrumbBar
            Divider()
            HStack(spacing: 0) {
                browserPlaceholder
                    .frame(width: browserWidth)
                SplitHandle(width: $browserWidth, range: 260...800)
                PlayerPlaceholderView()
            }
        }
        .frame(minWidth: 900, minHeight: 560)
    }

    private var breadcrumbBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "folder")
                .foregroundStyle(.secondary)
            Text("No folder open")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
    }

    private var browserPlaceholder: some View {
        VStack(spacing: 8) {
            Text("File browser")
                .font(.headline)
            Text("Open a folder to see its files.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var dependencyBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("Missing dependencies: \(missingTools).")
            Text(Dependencies.installCommand)
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)
            Spacer()
            Text("Restart the app after installing.")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.orange.opacity(0.12))
    }

    private var missingTools: String {
        var missing: [String] = []
        if dependencies.libmpvPath == nil {
            missing.append("libmpv")
        }
        if dependencies.ffmpegPath == nil {
            missing.append("ffmpeg")
        }
        return missing.joined(separator: " and ")
    }
}

#Preview {
    ContentView()
}
