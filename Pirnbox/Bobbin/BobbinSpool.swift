import SwiftUI

/// Role: Bobbin. The one custom-drawn hero. Remaining fills the glass column. A tap is Stitch.
struct BobbinSpool: View {
    var remaining: Int
    var capacity: Int
    var isSpent: Bool
    var showSuccess: Bool

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass
    @ScaledMetric(relativeTo: .body) private var flange: CGFloat = 22

    private var fillRatio: CGFloat {
        guard capacity > 0 else { return 0 }
        return min(1, CGFloat(remaining) / CGFloat(capacity))
    }

    private var figureFont: Font {
        typeSize >= .accessibility5 ? BobbinType.font(.title) : BobbinType.font(.display)
    }

    var body: some View {
        GeometryReader { geo in
            let width = spoolWidth(in: geo.size)
            let height = min(geo.size.height, geo.size.width * 1.35)
            VStack(spacing: BobbinSpace.step(1)) {
                spool(width: width, height: height - BobbinSpace.step(5))
                Text(isSpent ? "Bare spool" : "Tap to stitch")
                    .font(BobbinType.font(.body))
                    .foregroundStyle(BobbinPaint.ink)
                    .frame(maxWidth: .infinity)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isSpent ? "Bare bobbin. Remaining zero. Stitch writes a bare mark." : "Glass bobbin. Remaining \(BobbinType.figure(remaining)) of \(BobbinType.figure(capacity)).")
        .accessibilityHint("Stitches one unit from remaining.")
        .accessibilityAddTraits(.isButton)
    }

    private func spoolWidth(in size: CGSize) -> CGFloat {
        let ratio: CGFloat = sizeClass == .regular ? 0.88 : 0.78
        return min(size.width, max(size.width * ratio, BobbinSpace.step(18)))
    }

    private func spool(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            BobbinFlange()
                .fill(BobbinPaint.surface.opacity(0.92))
            BobbinFlange()
                .stroke(BobbinPaint.ink.opacity(0.18), lineWidth: 1)
            threadColumn
                .padding(.horizontal, width * 0.22)
                .padding(.vertical, flange)
            BobbinShine()
                .fill(BobbinPaint.surface.opacity(0.35))
                .allowsHitTesting(false)
            if BobbinArt.present(BobbinArt.controlFace) {
                Image(BobbinArt.controlFace)
                    .resizable()
                    .scaledToFit()
                    .opacity(0.22)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            VStack(spacing: BobbinSpace.step(1)) {
                Text(BobbinType.figure(remaining))
                    .font(figureFont)
                    .foregroundStyle(BobbinPaint.ink)
                    .monospacedDigit()
                    .contentTransition(reduceMotion ? .identity : .numericText())
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(isSpent ? "Bare" : "remaining")
                    .font(BobbinType.font(.caption))
                    .foregroundStyle(BobbinPaint.ink)
            }
            .animation(BobbinSpace.motion(reduce: reduceMotion), value: remaining)
            if showSuccess, BobbinArt.present(BobbinArt.successMark) {
                Image(BobbinArt.successMark)
                    .resizable()
                    .scaledToFit()
                    .frame(width: BobbinSpace.step(8), height: BobbinSpace.step(8))
                    .offset(y: -height * 0.28)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: width, height: height)
        .background {
            RoundedRectangle(cornerRadius: width * 0.28, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: width * 0.28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: width * 0.28, style: .continuous)
                .stroke(BobbinPaint.ink.opacity(0.12), lineWidth: 1)
        }
        .bobbinLift()
    }

    private var threadColumn: some View {
        GeometryReader { geo in
            let ratio = fillRatio
            ZStack(alignment: .bottom) {
                BobbinRound.cardShape
                    .fill(BobbinPaint.background.opacity(0.35))
                if isSpent {
                    BobbinRound.cardShape
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                        .foregroundStyle(BobbinPaint.ink.opacity(0.45))
                } else {
                    BobbinPaint.accent
                        .clipShape(BobbinRound.cardShape)
                        .frame(height: max(geo.size.height * ratio, remaining > 0 ? BobbinSpace.step(1) : 0))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .animation(BobbinSpace.motion(reduce: reduceMotion), value: remaining)
        }
    }
}

/// Role: Bobbin. Outer glass wall of the spool. Confined to the home hero.
struct BobbinFlange: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = rect.width * 0.12
        let mid = rect.insetBy(dx: inset, dy: rect.height * 0.08)
        path.addRoundedRect(in: mid, cornerSize: CGSize(width: mid.width * 0.28, height: mid.width * 0.28))
        let top = CGRect(x: rect.minX + rect.width * 0.08, y: rect.minY, width: rect.width * 0.84, height: rect.height * 0.16)
        let bottom = CGRect(x: rect.minX + rect.width * 0.08, y: rect.maxY - rect.height * 0.16, width: rect.width * 0.84, height: rect.height * 0.16)
        path.addEllipse(in: top)
        path.addEllipse(in: bottom)
        return path
    }
}

/// Role: Bobbin. Quiet highlight on the glass wall.
struct BobbinShine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let shine = CGRect(
            x: rect.minX + rect.width * 0.18,
            y: rect.minY + rect.height * 0.16,
            width: rect.width * 0.16,
            height: rect.height * 0.55
        )
        path.addRoundedRect(in: shine, cornerSize: CGSize(width: shine.width * 0.5, height: shine.width * 0.5))
        return path
    }
}
