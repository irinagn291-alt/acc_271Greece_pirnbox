import SwiftUI

/// Role: Bobbin. Conversation speech. Remaining and capacity vary width. Not a grid of twins.
struct BobbinSpeech: View {
    var title: String
    var line: String?
    var figure: String?
    var maxWidth: CGFloat
    var alignment: HorizontalAlignment = .leading
    var lifted: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: alignment, spacing: BobbinSpace.step(1)) {
            if let figure {
                Text(figure)
                    .font(BobbinType.font(.figure))
                    .foregroundStyle(BobbinPaint.ink)
                    .contentTransition(reduceMotion ? .identity : .numericText())
            }
            Text(title)
                .font(BobbinType.font(.body))
                .foregroundStyle(BobbinPaint.ink)
                .multilineTextAlignment(alignment == .trailing ? .trailing : .leading)
                .fixedSize(horizontal: false, vertical: true)
            if let line {
                Text(line)
                    .font(BobbinType.font(.body))
                    .foregroundStyle(BobbinPaint.ink)
                    .multilineTextAlignment(alignment == .trailing ? .trailing : .leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, BobbinSpace.step(2))
        .padding(.vertical, BobbinSpace.step(2))
        .frame(width: maxWidth, alignment: alignment == .trailing ? .trailing : .leading)
        .background(BobbinPaint.surface)
        .clipShape(BobbinRound.cardShape)
        .modifier(BobbinLiftGate(lifted: lifted))
    }
}

private struct BobbinLiftGate: ViewModifier {
    var lifted: Bool

    func body(content: Content) -> some View {
        if lifted {
            content.bobbinLift()
        } else {
            content
        }
    }
}

/// Role: Bobbin. Full-page empty. Art, headline, one line, full-width bottom CTA.
struct BobbinVacancy: View {
    var image: String
    var headline: String
    var line: String
    var actionTitle: String
    var usesAccent: Bool = false
    var action: () -> Void

    var body: some View {
        VStack(spacing: BobbinSpace.step(2)) {
            BobbinCutout(name: image, maxHeight: BobbinSpace.step(22))
            Text(headline)
                .font(BobbinType.font(.title))
                .foregroundStyle(BobbinPaint.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text(line)
                .font(BobbinType.font(.body))
                .foregroundStyle(BobbinPaint.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Spacer(minLength: 0)
            if usesAccent {
                Button(action: action) {
                    Text(actionTitle)
                        .frame(maxWidth: .infinity, minHeight: BobbinSpace.tap)
                        .contentShape(Rectangle())
                }
                .buttonStyle(BobbinAccentStyle())
            } else {
                Button(action: action) {
                    Text(actionTitle)
                        .frame(maxWidth: .infinity, minHeight: BobbinSpace.tap)
                        .contentShape(Rectangle())
                }
                .buttonStyle(BobbinQuietStyle())
            }
        }
        .padding(.horizontal, BobbinSpace.step(2))
        .padding(.bottom, BobbinSpace.step(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Role: Bobbin. Sheet header. Close is the whole 44pt chrome.
struct BobbinSheetBar: View {
    var title: String
    var closeLabel: String
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: BobbinSpace.step(1)) {
            Text(title)
                .font(BobbinType.font(.title))
                .foregroundStyle(BobbinPaint.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: BobbinSpace.step(1))
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(BobbinType.font(.body))
                    .foregroundStyle(BobbinPaint.ink)
                    .frame(width: BobbinSpace.tap, height: BobbinSpace.tap)
                    .background(BobbinPaint.surface)
                    .clipShape(BobbinRound.chipShape)
                    .bobbinLift()
                    .contentShape(BobbinRound.chipShape)
            }
            .buttonStyle(BobbinPressStyle())
            .accessibilityLabel(closeLabel)
        }
        .padding(.horizontal, BobbinSpace.step(2))
        .padding(.top, BobbinSpace.step(2))
    }
}

/// Role: Bobbin. Header destination. Whole chip is the hit, not the glyph.
struct BobbinCrumb: View {
    var title: String
    var symbol: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BobbinSpace.step(1)) {
                Image(systemName: symbol)
                    .font(BobbinType.font(.body))
                    .symbolRenderingMode(.monochrome)
                Text(title)
                    .font(BobbinType.font(.body))
                    .lineLimit(1)
            }
            .foregroundStyle(BobbinPaint.ink)
            .padding(.horizontal, BobbinSpace.step(2))
            .frame(minWidth: BobbinSpace.tap, minHeight: BobbinSpace.tap)
            .background(BobbinPaint.surface)
            .clipShape(BobbinRound.chipShape)
            .contentShape(BobbinRound.chipShape)
        }
        .buttonStyle(BobbinPressStyle())
        .accessibilityLabel(title)
    }
}
