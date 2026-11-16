import AppKit

final class TagDotsView: NSView {
    var colors: [TagColor] = [] {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        let diameter: CGFloat = 9
        let gap: CGFloat = 4
        let y = (bounds.height - diameter) / 2
        var x: CGFloat = 2

        for color in colors {
            let rect = NSRect(x: x, y: y, width: diameter, height: diameter)
            Self.nsColor(for: color).setFill()
            NSBezierPath(ovalIn: rect).fill()
            x += diameter + gap
        }
    }

    static func nsColor(for color: TagColor) -> NSColor {
        switch color {
        case .gray: .systemGray
        case .green: .systemGreen
        case .purple: .systemPurple
        case .blue: .systemBlue
        case .yellow: .systemYellow
        case .red: .systemRed
        case .orange: .systemOrange
        }
    }
}

final class TagCellView: NSTableCellView {
    let dots = TagDotsView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        dots.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dots)
        NSLayoutConstraint.activate([
            dots.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            dots.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            dots.centerYAnchor.constraint(equalTo: centerYAnchor),
            dots.heightAnchor.constraint(equalToConstant: 12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
