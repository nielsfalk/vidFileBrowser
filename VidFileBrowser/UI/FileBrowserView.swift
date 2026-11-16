import SwiftUI

struct FileBrowserView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }

            FileTableView(
                items: model.items,
                sortProperty: model.sortProperty,
                selection: $model.selection,
                onActivate: model.activate,
                buildContextMenu: makeContextMenu
            )

            Divider()

            HStack(spacing: 8) {
                Text("^[\(model.items.count) item](inflect: true)")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Spacer()

                Picker("Sort by", selection: $model.sortProperty) {
                    ForEach(SortProperty.allCases) { property in
                        Text(property.title).tag(property)
                    }
                }
                .pickerStyle(.menu)
                .fixedSize()

                Button {
                    model.sortAscending.toggle()
                } label: {
                    Image(systemName: model.sortAscending ? "arrow.up" : "arrow.down")
                }
                .buttonStyle(.borderless)
                .help(model.sortAscending ? "Ascending order" : "Descending order")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func makeContextMenu(for item: FileItem, menu: NSMenu) {
        let tagsItem = NSMenuItem(title: "Tags", action: nil, keyEquivalent: "")
        let tagsMenu = NSMenu()

        for color in TagColor.allCases {
            let isOn = item.tagColors.contains(color)
            let menuItem = ClosureMenuItem(title: FinderTagService.defaultName(for: color)) { [model] in
                model.toggleTag(color, on: item)
            }
            menuItem.state = isOn ? .on : .off
            tagsMenu.addItem(menuItem)
        }

        tagsMenu.addItem(.separator())
        tagsMenu.addItem(ClosureMenuItem(title: "Remove All Tags") { [model] in
            model.removeAllTags(from: item)
        })

        tagsItem.submenu = tagsMenu
        menu.addItem(tagsItem)

        menu.addItem(ClosureMenuItem(title: "Rename…") { [model] in
            if let name = RenamePrompt.run(currentName: item.name) {
                model.rename(item, to: name)
            }
        })

        let favorites = model.favorites.folders.compactMap { folder -> (FavoriteFolder, URL)? in
            guard let url = model.favorites.url(for: folder) else { return nil }
            return (folder, url)
        }

        if !favorites.isEmpty {
            let moveToItem = NSMenuItem(title: "Move to", action: nil, keyEquivalent: "")
            let moveToMenu = NSMenu()
            for (folder, url) in favorites {
                moveToMenu.addItem(ClosureMenuItem(title: folder.name) { [model] in
                    model.move(item, to: url)
                })
            }
            moveToItem.submenu = moveToMenu
            menu.addItem(moveToItem)
        }
    }
}
