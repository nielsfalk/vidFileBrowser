import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    private let dependencies: Dependencies
    @State private var model = AppModel()
    @State private var browserWidth: CGFloat = 440
    @State private var isDropTarget = false

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
                FileBrowserView(model: model)
                    .frame(width: browserWidth)
                SplitHandle(width: $browserWidth, range: 260...800)
                PlayerPlaceholderView(item: model.selectedItem)
            }
        }
        .frame(minWidth: 900, minHeight: 560)
        .overlay {
            if isDropTarget {
                Rectangle()
                    .strokeBorder(Color.accentColor, lineWidth: 3)
                    .allowsHitTesting(false)
            }
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $isDropTarget) { providers in
            guard let provider = providers.first else { return false }
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil),
                      url.hasDirectoryPath
                else {
                    return
                }
                Task { @MainActor in
                    model.open(url)
                }
            }
            return true
        }
    }

    private var breadcrumbBar: some View {
        HStack(spacing: 4) {
            Image(systemName: "folder")
                .foregroundStyle(.secondary)

            if breadcrumbs.isEmpty {
                Text("No folder open")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(breadcrumbs.enumerated()), id: \.element.id) { index, crumb in
                    if index > 0 {
                        Image(systemName: "chevron.compact.right")
                            .foregroundStyle(.tertiary)
                    }
                    Button {
                        model.open(crumb.url)
                    } label: {
                        Text(crumb.title)
                            .lineLimit(1)
                            .foregroundStyle(index == breadcrumbs.count - 1 ? .primary : .secondary)
                            .fontWeight(index == breadcrumbs.count - 1 ? .semibold : .regular)
                    }
                    .buttonStyle(.plain)
                    .help(crumb.url.path)
                }
            }

            Spacer()
            Button("Open Folder…", action: chooseFolder)
                .keyboardShortcut("o", modifiers: .command)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
    }

    private var breadcrumbs: [Breadcrumb] {
        BreadcrumbBuilder.segments(for: model.directory)
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

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Open"
        panel.message = "Choose a folder to browse"

        if panel.runModal() == .OK, let url = panel.url {
            model.open(url)
        }
    }
}

#Preview {
    ContentView()
}
