import SwiftUI

/// A draggable divider between the file browser and the player.
struct SplitHandle: View {
    @Binding var width: CGFloat
    let range: ClosedRange<CGFloat>

    @State private var widthAtDragStart: CGFloat?

    var body: some View {
        ZStack {
            Color.clear
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(width: 1)
        }
        .frame(width: 8)
        .contentShape(Rectangle())
        .onHover { inside in
            if inside {
                NSCursor.resizeLeftRight.set()
            } else {
                NSCursor.arrow.set()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    if widthAtDragStart == nil {
                        widthAtDragStart = width
                    }
                    let start = widthAtDragStart ?? width
                    width = min(max(start + value.translation.width, range.lowerBound), range.upperBound)
                }
                .onEnded { _ in
                    widthAtDragStart = nil
                }
        )
        .accessibilityLabel("Resize the file browser")
    }
}
