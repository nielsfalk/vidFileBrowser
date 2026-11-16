import SwiftUI

struct PlayerView: View {
    let model: AppModel

    @State private var controlsVisible = true
    @State private var hideTask: Task<Void, Never>?

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
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            model.selectionDidChange()
        }
        .onDisappear {
            hideTask?.cancel()
        }
        .onContinuousHover { phase in
            switch phase {
            case .active:
                revealControls()
                scheduleHide()
            case .ended:
                hideTask?.cancel()
            }
        }
        .onChange(of: player.state) { _, state in
            if state == .playing {
                scheduleHide()
            } else {
                revealControls()
                hideTask?.cancel()
            }
        }
    }

    private var showsControls: Bool {
        guard player.duration > 0, player.state != .idle else { return false }
        return controlsVisible || player.state == .paused || player.state == .ended
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

    private func revealControls() {
        withAnimation(.easeInOut(duration: 0.15)) {
            controlsVisible = true
        }
    }

    private func scheduleHide() {
        guard player.state == .playing else { return }
        hideTask?.cancel()

        hideTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.25)) {
                    controlsVisible = false
                }
            }
        }
    }
}
