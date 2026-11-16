import AppKit
import SwiftUI

struct FileTableView: NSViewRepresentable {
    let items: [FileItem]
    let sortProperty: SortProperty
    @Binding var selection: Set<FileItem.ID>

    private static let nameColumnID = NSUserInterfaceItemIdentifier("name")
    private static let valueColumnID = NSUserInterfaceItemIdentifier("value")
    private static let tagsColumnID = NSUserInterfaceItemIdentifier("tags")

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let table = NSTableView()
        table.dataSource = context.coordinator
        table.delegate = context.coordinator
        table.allowsMultipleSelection = false
        table.usesAlternatingRowBackgroundColors = true
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

        let scrollView = NSScrollView()
        scrollView.documentView = table
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let table = scrollView.documentView as? NSTableView else { return }

        context.coordinator.parent = self
        if context.coordinator.items != items {
            context.coordinator.items = items
            table.reloadData()
        }

        table.tableColumn(withIdentifier: Self.valueColumnID)?.title = sortProperty.columnTitle

        let rows = IndexSet(items.enumerated().compactMap { index, item in
            selection.contains(item.id) ? index : nil
        })
        if table.selectedRowIndexes != rows {
            table.selectRowIndexes(rows, byExtendingSelection: false)
        }
    }

    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        var parent: FileTableView
        var items: [FileItem] = []

        init(_ parent: FileTableView) {
            self.parent = parent
            items = parent.items
        }

        func numberOfRows(in tableView: NSTableView) -> Int {
            items.count
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard let tableColumn, items.indices.contains(row) else { return nil }
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

        func tableViewSelectionDidChange(_ notification: Notification) {
            guard let table = notification.object as? NSTableView else { return }
            let ids = table.selectedRowIndexes.compactMap { index in
                items.indices.contains(index) ? items[index].id : nil
            }
            parent.selection = Set(ids)
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
