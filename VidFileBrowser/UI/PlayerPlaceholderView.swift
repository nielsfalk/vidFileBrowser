import SwiftUI

struct PlayerPlaceholderView: View {
    let item: FileItem?

    var body: some View {
        ZStack {
            Color.black
            VStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 44))
                    .foregroundStyle(.white.opacity(0.5))
                Text(title)
                    .foregroundStyle(.white.opacity(0.85))
                if let item {
                    Text(item.name)
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.horizontal, 24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var iconName: String {
        switch item?.kind {
        case .video: "play.rectangle"
        case .image: "photo"
        case .other: "doc"
        case nil: "play.rectangle"
        }
    }

    private var title: String {
        guard let item else { return "No file selected" }
        if item.isDirectory {
            return "Folder"
        }
        return item.kind.isPlayable ? item.kind.title : "This file type is not played"
    }
}
