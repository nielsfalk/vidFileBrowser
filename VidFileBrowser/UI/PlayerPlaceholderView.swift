import SwiftUI

struct PlayerPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.black
            VStack(spacing: 12) {
                Image(systemName: "play.rectangle")
                    .font(.system(size: 44))
                    .foregroundStyle(.white.opacity(0.5))
                Text("No file selected")
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
