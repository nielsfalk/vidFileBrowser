import AppKit
import SwiftUI

struct FavoritesSettingsView: View {
    @Bindable var store: FavoritesStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
        .frame(width: 520, height: 340)
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
