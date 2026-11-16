import SwiftUI

struct FileBrowserView: View {
    @Bindable var model: AppModel
    private let sortProperty: SortProperty = .date

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
                sortProperty: sortProperty,
                selection: $model.selection
            )

            Divider()

            HStack {
                Text("^[\(model.items.count) item](inflect: true)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
