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
                onActivate: model.activate
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
}
