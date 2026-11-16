import SwiftUI

struct PlayerView: View {
    let model: AppModel

    @State private var controlsVisible = true
    @State private var hideTask: Task<Void, Never>?

    private var player: PlayerController { model.player }

    var body: some View {
        ZStack {
            MPVVideoView(controller: player)

            if let image = model.image {
                ImageCanvas(image: image)
            }

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

            if model.isTrimming {
                VStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Trimming…")
                        .font(.callout)
                        .foregroundStyle(.white)
                }
                .padding(20)
                .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            model.selectionDidChange()
        }
        .contextMenu {
            playerContextMenu
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

    @ViewBuilder
    private var playerContextMenu: some View {
        Button("Play/Pause") {
            player.togglePlayPause()
        }
        .disabled(player.currentURL == nil)

        Button("Trim Left at Playhead") {
            model.trimLeft()
        }
        .disabled(player.currentURL == nil || model.isTrimming)

        Button("Trim Right at Playhead") {
            model.trimRight()
        }
        .disabled(player.currentURL == nil || model.isTrimming)

        if let item = model.selectedItem {
            Divider()

            Menu("Tags") {
                ForEach(TagColor.allCases, id: \.self) { color in
                    Toggle(
                        FinderTagService.defaultName(for: color),
                        isOn: Binding(
                            get: { item.tagColors.contains(color) },
                            set: { _ in model.toggleTag(color, on: item) }
                        )
                    )
                }

                Divider()

                Button("Remove All Tags") {
                    model.removeAllTags(from: item)
                }
            }

            if !model.favorites.folders.isEmpty {
                Menu("Move to") {
                    ForEach(model.favorites.folders) { folder in
                        if let url = model.favorites.url(for: folder) {
                            Button(folder.name) {
                                model.move(item, to: url)
                            }
                        }
                    }
                }
            }

            Button("Rename…") {
                if let name = RenamePrompt.run(currentName: item.name) {
                    model.rename(item, to: name)
                }
            }
        }

        Divider()

        Button("Enter Full Screen") {
            NSApp.keyWindow?.toggleFullScreen(nil)
        }
    }

    private var message: String? {        switch player.state {
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
