import SwiftUI

/// Shows in the top left corner while one or more files are being trimmed.
struct TrimIndicatorView: View {
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
                .tint(.white)
            Text(count == 1 ? "Trimming 1 file…" : "Trimming \(count) files…")
                .font(.callout)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.75), in: Capsule())
        .allowsHitTesting(false)
    }
}

#Preview {
    TrimIndicatorView(count: 2)
        .padding()
        .background(Color.gray)
}
