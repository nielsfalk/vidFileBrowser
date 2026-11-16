import AppKit
import SwiftUI

struct FileTableView: NSViewRepresentable {
    let items: [FileItem]
    let sortProperty: SortProperty
    @Binding var selection: Set<FileItem.ID>
    var onActivate: ((FileItem) -> Void)? = nil
    var buildContextMenu: ((FileItem, NSMenu) -> Void)? = nil
    var buildMoveToMenu: ((FileItem, NSMenu) -> Void)? = nil
    var onDropFiles: (([URL]) -> Bool)? = nil
    var onShortcut: ((BrowserShortcut) -> Void)? = nil
    var onCopySelection: (() -> Void)? = nil
    var onCutSelection: (() -> Void)? = nil
    var onPaste: (() -> Void)? = nil

    private static let nameColumnID = NSUserInterfaceItemIdentifier("name")
    private static let valueColumnID = NSUserInterfaceItemIdentifier("value")
    private static let tagsColumnID = NSUserInterfaceItemIdentifier("tags")

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let table = FileTable()
        table.dataSource = context.coordinator
        table.delegate = context.coordinator
        table.target = context.coordinator
        table.doubleAction = #selector(Coordinator.activateClickedRow(_:))
        table.onActivateRow = { [weak coordinator = context.coordinator] row in
            coordinator?.activate(row: row)
        }
        table.onShowContextMenu = { [weak coordinator = context.coordinator] in
            coordinator?.showContextMenu()
        }
        table.onShowMoveToMenu = { [weak coordinator = context.coordinator] in
            coordinator?.showMoveToMenu()
        }
        table.onDropFiles = { [weak coordinator = context.coordinator] urls in
            coordinator?.parent.onDropFiles?(urls) ?? false
        }
        table.onShortcut = { [weak coordinator = context.coordinator] shortcut in
            coordinator?.parent.onShortcut?(shortcut)
        }
        table.onCopy = { [weak coordinator = context.coordinator] in
            coordinator?.parent.onCopySelection?()
        }
        table.onCut = { [weak coordinator = context.coordinator] in
            coordinator?.parent.onCutSelection?()
        }
        table.onPaste = { [weak coordinator = context.coordinator] in
            coordinator?.parent.onPaste?()
        }
        table.allowsMultipleSelection = true
        table.usesAlternatingRowBackgroundColors = true
        table.setDraggingSourceOperationMask([.copy, .move], forLocal: true)
        table.setDraggingSourceOperationMask(.copy, forLocal: false)
        table.rowHeight = 22
        table.style = .inset
        table.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        table.headerView = NSTableHeaderView()

        let nameColumn = NSTableColumn(identifier: Self.nameColumnID)
        nameColumn.title = "Name"
        nameColumn.width = 260
        nameColumn.minWidth = 120
        table.addTableColumn(nameColumn)

        let valueColumn = NSTableColumn(identifier: Self.valueColumnID)
        valueColumn.title = sortProperty.columnTitle
        valueColumn.width = 160
        valueColumn.minWidth = 90
        table.addTableColumn(valueColumn)

        let tagsColumn = NSTableColumn(identifier: Self.tagsColumnID)
        tagsColumn.title = "Tags"
        tagsColumn.width = 64
        tagsColumn.minWidth = 44
        table.addTableColumn(tagsColumn)

        let contextMenu = NSMenu()
        contextMenu.delegate = context.coordinator
        table.menu = contextMenu
        context.coordinator.tableView = table

        let scrollView = NSScrollView()
        scrollView.documentView = table
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        DispatchQueue.main.async {
            table.window?.makeFirstResponder(table)
        }
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let table = scrollView.documentView as? NSTableView else { return }

        context.coordinator.parent = self
        if context.coordinator.items != items {
            context.coordinator.items = items
            table.reloadData()
            DispatchQueue.main.async {
                table.window?.makeFirstResponder(table)
            }
        }

        table.tableColumn(withIdentifier: Self.valueColumnID)?.title = sortProperty.columnTitle

        let rows = IndexSet(items.enumerated().compactMap { index, item in
            selection.contains(item.id) ? index : nil
        })
        if table.selectedRowIndexes != rows {
            table.selectRowIndexes(rows, byExtendingSelection: false)
        }
    }

    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate {
        var parent: FileTableView
        var items: [FileItem] = []
        weak var tableView: NSTableView?

        init(_ parent: FileTableView) {
            self.parent = parent
            items = parent.items
        }

        func numberOfRows(in tableView: NSTableView) -> Int {
            items.count
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {            guard let tableColumn, items.indices.contains(row) else { return nil }
            let item = items[row]

            switch tableColumn.identifier {
            case FileTableView.nameColumnID:
                return nameCell(in: tableView, item: item)
            case FileTableView.valueColumnID:
                return valueCell(in: tableView, item: item)
            case FileTableView.tagsColumnID:
                return tagCell(in: tableView, item: item)
            default:
                return nil
            }
        }

        func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
            guard items.indices.contains(row) else { return nil }
            return items[row].url as NSURL
        }

        func tableViewSelectionDidChange(_ notification: Notification) {            guard let table = notification.object as? NSTableView else { return }
            let ids = table.selectedRowIndexes.compactMap { index in
                items.indices.contains(index) ? items[index].id : nil
            }
            parent.selection = Set(ids)
        }

        func activate(row: Int) {
            guard items.indices.contains(row) else { return }
            parent.onActivate?(items[row])
        }

        @objc func activateClickedRow(_ sender: Any?) {
            guard let table = sender as? NSTableView else { return }
            let row = table.clickedRow >= 0 ? table.clickedRow : table.selectedRow
            activate(row: row)
        }

        func menuNeedsUpdate(_ menu: NSMenu) {
            menu.removeAllItems()

            guard let tableView else { return }
            let row = tableView.clickedRow >= 0 ? tableView.clickedRow : tableView.selectedRow
            guard items.indices.contains(row), let buildContextMenu = parent.buildContextMenu else { return }
            buildContextMenu(items[row], menu)
        }

        func showContextMenu() {
            guard let table = tableView, let menu = table.menu else { return }
            menuNeedsUpdate(menu)
            guard !menu.items.isEmpty else { return }
            popUp(menu, at: table.selectedRow, in: table)
        }

        func showMoveToMenu() {
            guard let table = tableView, items.indices.contains(table.selectedRow) else { return }

            let menu = NSMenu()
            if let buildMoveToMenu = parent.buildMoveToMenu {
                buildMoveToMenu(items[table.selectedRow], menu)
            }
            guard !menu.items.isEmpty else {
                NSSound.beep()
                return
            }
            popUp(menu, at: table.selectedRow, in: table)
        }

        private func popUp(_ menu: NSMenu, at row: Int, in table: NSTableView) {
            let rowRect = row >= 0 ? table.rect(ofRow: row) : NSRect(x: 8, y: 8, width: 1, height: 1)
            let point = NSPoint(x: rowRect.minX + 24, y: rowRect.maxY)
            menu.popUp(positioning: nil, at: point, in: table)
        }

        private func nameCell(in tableView: NSTableView, item: FileItem) -> NSView {
            let identifier = NSUserInterfaceItemIdentifier("nameCell")
            let cell: NSTableCellView
            if let reused = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView {
                cell = reused
            } else {
                cell = NSTableCellView()
                cell.identifier = identifier

                let imageView = NSImageView()
                imageView.translatesAutoresizingMaskIntoConstraints = false
                cell.addSubview(imageView)
                cell.imageView = imageView

                let textField = NSTextField(labelWithString: "")
                textField.translatesAutoresizingMaskIntoConstraints = false
                textField.lineBreakMode = .byTruncatingMiddle
                cell.addSubview(textField)
                cell.textField = textField

                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
                    imageView.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                    imageView.widthAnchor.constraint(equalToConstant: 16),
                    imageView.heightAnchor.constraint(equalToConstant: 16),
                    textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 6),
                    textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -2),
                    textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
                ])
            }

            cell.textField?.stringValue = item.name
            cell.imageView?.image = NSWorkspace.shared.icon(forFile: item.url.path)
            return cell
        }

        private func valueCell(in tableView: NSTableView, item: FileItem) -> NSView {
            let identifier = NSUserInterfaceItemIdentifier("valueCell")
            let cell: NSTableCellView
            if let reused = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView {
                cell = reused
            } else {
                cell = NSTableCellView()
                cell.identifier = identifier

                let textField = NSTextField(labelWithString: "")
                textField.translatesAutoresizingMaskIntoConstraints = false
                textField.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
                textField.textColor = .secondaryLabelColor
                textField.lineBreakMode = .byTruncatingTail
                cell.addSubview(textField)
                cell.textField = textField

                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
                    textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -2),
                    textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
                ])
            }

            cell.textField?.stringValue = item.sortValueText(for: parent.sortProperty)
            return cell
        }

        private func tagCell(in tableView: NSTableView, item: FileItem) -> NSView {
            let identifier = NSUserInterfaceItemIdentifier("tagCell")
            let cell: TagCellView
            if let reused = tableView.makeView(withIdentifier: identifier, owner: self) as? TagCellView {
                cell = reused
            } else {
                cell = TagCellView()
                cell.identifier = identifier
            }

            cell.dots.colors = item.tagColors
            return cell
        }
    }
}

private final class FileTable: NSTableView {
    var onActivateRow: ((Int) -> Void)?
    var onShowContextMenu: (() -> Void)?
    var onShowMoveToMenu: (() -> Void)?
    var onDropFiles: (([URL]) -> Bool)?
    var onShortcut: ((BrowserShortcut) -> Void)?
    var onCopy: (() -> Void)?
    var onCut: (() -> Void)?
    var onPaste: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func copy(_ sender: Any?) {
        onCopy?()
    }

    @objc func cut(_ sender: Any?) {
        onCut?()
    }

    @objc func paste(_ sender: Any?) {
        onPaste?()
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        droppedFiles(from: sender).isEmpty ? [] : .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        draggingEntered(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = droppedFiles(from: sender)
        guard !urls.isEmpty else { return false }
        return onDropFiles?(urls) ?? false
    }

    private func droppedFiles(from sender: NSDraggingInfo) -> [URL] {
        let urls = sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] ?? []
        return urls.filter { url in
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
            return exists && !isDirectory.boolValue
        }
    }

    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if let shortcut = BrowserShortcut(event: event) {
            if shortcut == .exitFullScreen, window?.styleMask.contains(.fullScreen) != true {
                super.keyDown(with: event)
                return
            }
            onShortcut?(shortcut)
            return
        }

        if flags.isEmpty, let characters = event.charactersIgnoringModifiers?.lowercased() {
            switch characters {
            case "y":
                onShowContextMenu?()
                return
            case "x":
                onShowMoveToMenu?()
                return
            default:
                break
            }
        }

        if event.keyCode == 36 || event.keyCode == 76 {
            onActivateRow?(selectedRow)
            return
        }
        super.keyDown(with: event)
    }
}
