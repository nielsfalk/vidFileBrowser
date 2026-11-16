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

            List(model.items) { item in
                HStack(spacing: 8) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text(item.name)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Text(item.sortValueText(for: .date))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.inset)

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
