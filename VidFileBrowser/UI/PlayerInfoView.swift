import SwiftUI

struct PlayerInfoView: View {
    let state: PlayerInfoState

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Image(systemName: state.systemImage)
                    .font(.system(size: 44))
                    .foregroundStyle(.white.opacity(0.35))
                Text(state.title)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                Text(state.subtitle)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            ShortcutList()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

struct ShortcutList: View {
    private static let entries: [(keys: String, action: String)] = [
        ("Space", "Play / pause"),
        ("← / →", "Skip 10 seconds"),
        (", / .", "Skip 30 seconds"),
        ("n / m", "Trim left / right at the playhead"),
        ("↑ / ↓", "Previous / next file"),
        ("Enter", "Open folder"),
        ("y / x", "Context menu / Move to menu"),
        ("⌘C / ⌘X / ⌘V", "Copy / cut / paste files"),
        ("f / Esc", "Full screen on / off")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Shortcuts")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.45))
                .padding(.bottom, 2)

            ForEach(Array(Self.entries.enumerated()), id: \.offset) { _, entry in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(entry.keys)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 120, alignment: .leading)
                    Text(entry.action)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .padding(14)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }
}
