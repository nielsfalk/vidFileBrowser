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
                buildContextMenu: makeContextMenu,
                buildMoveToMenu: makeMoveToMenu,
                onDropFiles: model.importFiles,
                onCopySelection: model.copySelection,
                onCutSelection: model.cutSelection,
                onPaste: { model.paste() }
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

    private func targets(for item: FileItem) -> [FileItem] {
        if model.selection.contains(item.id) {
            let selected = model.selectedItems
            if !selected.isEmpty {
                return selected
            }
        }
        return [item]
    }

    private func makeContextMenu(for item: FileItem, menu: NSMenu) {
        let targets = targets(for: item)

        let tagsItem = NSMenuItem(title: "Tags", action: nil, keyEquivalent: "")
        let tagsMenu = NSMenu()

        for color in TagColor.allCases {
            let isOn = targets.allSatisfy { $0.tagColors.contains(color) }
            let menuItem = ClosureMenuItem(title: FinderTagService.defaultName(for: color)) { [model] in
                model.toggleTag(color, on: targets)
            }
            menuItem.state = isOn ? .on : .off
            tagsMenu.addItem(menuItem)
        }

        tagsMenu.addItem(.separator())
        tagsMenu.addItem(ClosureMenuItem(title: "Remove All Tags") { [model] in
            model.removeAllTags(from: targets)
        })

        tagsItem.submenu = tagsMenu
        menu.addItem(tagsItem)

        if targets.count == 1, let single = targets.first {
            menu.addItem(ClosureMenuItem(title: "Rename…") { [model] in
                if let name = RenamePrompt.run(currentName: single.name) {
                    model.rename(single, to: name)
                }
            })
        }

        menu.addItem(.separator())
        menu.addItem(ClosureMenuItem(title: "Reveal in Finder") { [model] in
            model.revealInFinder(targets)
        })
        menu.addItem(ClosureMenuItem(title: "Copy Path") { [model] in
            model.copyPaths(of: targets)
        })
        menu.addItem(.separator())
        menu.addItem(ClosureMenuItem(title: "Move to Trash") { [model] in
            model.moveToTrash(targets)
        })

        let moveToMenu = NSMenu()
        makeMoveToMenu(for: targets, menu: moveToMenu)
        if !moveToMenu.items.isEmpty {
            let moveToItem = NSMenuItem(title: "Move to", action: nil, keyEquivalent: "")
            moveToItem.submenu = moveToMenu
            menu.addItem(moveToItem)
        }
    }

    private func makeMoveToMenu(for item: FileItem, menu: NSMenu) {
        makeMoveToMenu(for: targets(for: item), menu: menu)
    }

    private func makeMoveToMenu(for targets: [FileItem], menu: NSMenu) {
        for folder in model.favorites.folders {
            guard let url = model.favorites.url(for: folder) else { continue }
            menu.addItem(ClosureMenuItem(title: folder.name) { [model] in
                model.move(targets, to: url)
            })
        }
    }
}
