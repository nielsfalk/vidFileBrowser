import SwiftUI

struct PlayerProgressBar: View {
    let player: PlayerController

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.25))
                Capsule()
                    .fill(.white.opacity(0.9))
                    .frame(width: geometry.size.width * player.position.fraction)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard geometry.size.width > 0 else { return }
                        let fraction = min(max(value.location.x / geometry.size.width, 0), 1)
                        player.seek(to: fraction * player.duration)
                    }
            )
        }
        .frame(height: 16)
    }
}

struct PlayerControlsView: View {
    let player: PlayerController

    var body: some View {
        HStack(spacing: 10) {
            Text(TimeFormatter.string(from: player.currentTime))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))

            PlayerProgressBar(player: player)

            Text(TimeFormatter.string(from: player.duration))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.55))
    }
}
