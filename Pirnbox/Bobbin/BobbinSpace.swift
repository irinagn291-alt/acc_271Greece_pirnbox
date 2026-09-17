import SwiftUI

/// Role: Bobbin. Spacing, radii, elevation, and quiet motion. Views never invent a second kit.
enum BobbinSpace {
    static let unit: CGFloat = 8
    static let tap: CGFloat = 44
    static let pressScale: CGFloat = 0.98
    static let fade = Animation.easeOut(duration: 0.18)

    static func step(_ count: Int) -> CGFloat {
        unit * CGFloat(count)
    }

    static func motion(reduce: Bool) -> Animation? {
        reduce ? nil : fade
    }
}

/// Role: Bobbin. One radius language. Cards and sheets 20, chips 12.
enum BobbinRound {
    static let card: CGFloat = 20
    static let chip: CGFloat = 12

    static var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: card, style: .continuous)
    }

    static var chipShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: chip, style: .continuous)
    }
}

extension View {
    func bobbinLift() -> some View {
        shadow(color: BobbinPaint.ink.opacity(0.10), radius: 16, x: 0, y: 8)
    }

    func bobbinCardSurface() -> some View {
        background(BobbinPaint.surface)
            .clipShape(BobbinRound.cardShape)
            .bobbinLift()
    }

    func bobbinHit() -> some View {
        frame(minWidth: BobbinSpace.tap, minHeight: BobbinSpace.tap)
            .contentShape(Rectangle())
    }
}
