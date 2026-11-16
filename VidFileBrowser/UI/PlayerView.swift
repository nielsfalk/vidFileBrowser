import SwiftUI

struct PlayerView: View {
    let model: AppModel

    private var player: PlayerController { model.player }

    var body: some View {
        ZStack {
            MPVVideoView(controller: player)

            if let message {
                VStack(spacing: 10) {
                    Image(systemName: "play.rectangle")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.4))
                    Text(message)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.65))
                        .padding(.horizontal, 32)
                }
            }

            if showsControls {
                VStack {
                    Spacer()
                    PlayerControlsView(player: player)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            model.selectionDidChange()
        }
    }

    private var showsControls: Bool {
        player.duration > 0 && player.state != .idle
    }

    private var message: String? {
        switch player.state {
        case .failed(let reason):
            return reason
        case .idle:
            if let item = model.selectedItem {
                return item.kind.isPlayable
                    ? "Loading \(item.name)…"
                    : "This file type is not played"
            }
            return "No file selected"
        default:
            return nil
        }
    }
}
