import AppKit
import SwiftUI

struct SettingsView: View {
    @Bindable var store: FavoritesStore

    @AppStorage(AppSettings.Key.autoTagEnabled) private var autoTagEnabled = false
    @AppStorage(AppSettings.Key.autoTagColor) private var autoTagColor = TagColor.green.rawValue

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Tag played files after 2 seconds", isOn: $autoTagEnabled)

                Picker("Tag", selection: $autoTagColor) {
                    ForEach(TagColor.allCases, id: \.self) { color in
                        Text(FinderTagService.defaultName(for: color))
                            .tag(color.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .fixedSize()
                .disabled(!autoTagEnabled)
            }
            .padding(12)

            Divider()

            List {
                ForEach(store.folders) { folder in
                    HStack(spacing: 8) {
                        Image(systemName: "folder")
                            .foregroundStyle(.secondary)
                        Text(folder.name)
                        Spacer()
                        Text(store.url(for: folder)?.path ?? "Folder not found")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .onMove { source, destination in
                    store.move(fromOffsets: source, toOffset: destination)
                }
                .onDelete { offsets in
                    store.remove(atOffsets: offsets)
                }
            }

            HStack {
                Button("Add Folder…", action: addFolder)
                Button("Remove") {
                    if !store.folders.isEmpty {
                        store.remove(atOffsets: [store.folders.count - 1])
                    }
                }
                .disabled(store.folders.isEmpty)
                Spacer()
                Text("\(store.folders.count) favorites")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
        }
        .frame(width: 520, height: 420)
    }

    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Add"

        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            try? store.add(url)
        }
    }
}
