import SwiftUI

/// Role: Bobbin. One-shot cover of three pages. Skip writes defaults. Re-runnable from Settings.
@MainActor
struct BobbinOnboarding: View {
    var onContinue: () -> Void
    var onSkip: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: BobbinSpace.step(2)) {
            Group {
                switch page {
                case 0:
                    pageBody(
                        image: BobbinArt.onboarding1,
                        title: "Thread on the glass",
                        line: "See remaining against capacity on a glass bobbin. Home is the spool, not a diary."
                    )
                case 1:
                    pageBody(
                        image: BobbinArt.onboarding2,
                        title: "Tap to stitch",
                        line: "Each tap spends one unit. At zero, a tap writes Bare and remaining stays at zero."
                    )
                default:
                    pageBody(
                        image: BobbinArt.onboarding3,
                        title: "Reload the spool",
                        line: "Reload restores remaining to capacity and files a mark on the day."
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(BobbinSpace.motion(reduce: reduceMotion), value: page)
            VStack(spacing: BobbinSpace.step(1)) {
                Button {
                    if page < 2 {
                        page += 1
                    } else {
                        onContinue()
                    }
                } label: {
                    Text(page < 2 ? "Continue" : "Stitch")
                        .frame(maxWidth: .infinity, minHeight: BobbinSpace.tap)
                        .contentShape(Rectangle())
                }
                .buttonStyle(BobbinAccentStyle())
                Button(action: onSkip) {
                    Text("Skip")
                        .frame(maxWidth: .infinity, minHeight: BobbinSpace.tap)
                        .contentShape(Rectangle())
                }
                .buttonStyle(BobbinQuietStyle())
            }
        }
        .padding(BobbinSpace.step(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BobbinPaint.background.ignoresSafeArea())
    }

    private func pageBody(image: String, title: String, line: String) -> some View {
        VStack(alignment: .leading, spacing: BobbinSpace.step(2)) {
            BobbinCutout(name: image, maxHeight: BobbinSpace.step(28))
            Text(title)
                .font(BobbinType.font(.title))
                .foregroundStyle(BobbinPaint.ink)
            Text(line)
                .font(BobbinType.font(.body))
                .foregroundStyle(BobbinPaint.muted)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
