import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    private let dependencies: Dependencies
    private let settings: AppSettings
    @State private var model: AppModel
    @State private var browserWidth: CGFloat
    @State private var isDropTarget = false

    init(model: AppModel? = nil, dependencies: Dependencies = DependencyLocator.locate(), settings: AppSettings = AppSettings()) {
        self.dependencies = dependencies
        self.settings = settings

        let width = CGFloat(settings.browserWidth)
        _browserWidth = State(initialValue: min(max(width, 260), 800))
        _model = State(initialValue: model ?? AppModel(settings: settings))
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
                PlayerView(model: model)
            }
        }
        .frame(minWidth: 900, minHeight: 560)
        .background(WindowConfigurator().frame(width: 0, height: 0))
        .onChange(of: browserWidth) { _, newWidth in
            settings.browserWidth = Double(newWidth)
        }
        .onChange(of: model.selection) { _, _ in
            model.selectionDidChange()
        }
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
        .alert("Trim failed", isPresented: trimErrorPresented) {
            Button("OK", role: .cancel) {
                model.dismissTrimError()
            }
        } message: {
            Text(model.trimError ?? "")
        }
    }

    private var trimErrorPresented: Binding<Bool> {
        Binding(
            get: { model.trimError != nil },
            set: { presented in
                if !presented {
                    model.dismissTrimError()
                }
            }
        )
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
