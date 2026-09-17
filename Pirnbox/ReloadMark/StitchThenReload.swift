import SwiftUI

/// Role: ReloadMark. Twist screen for stitch-then-reload. Home already shows remaining versus capacity.
@MainActor
struct StitchThenReload: View {
    @Bindable var watch: BobbinWatch
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            BobbinSheetBar(title: "Stitch then reload", closeLabel: "Close stitch then reload") {
                dismiss()
            }
            if watch.persistFailed {
                BobbinVacancy(
                    image: BobbinArt.twistHero,
                    headline: "The spool could not be read.",
                    line: "Retry, then stitch on the glass.",
                    actionTitle: "Retry",
                    usesAccent: false
                ) {
                    Task { await watch.retryLoad() }
                }
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BobbinPaint.background.ignoresSafeArea())
    }

    private var populated: some View {
        VStack(alignment: .leading, spacing: BobbinSpace.step(2)) {
            BobbinCutout(name: BobbinArt.twistHero, maxHeight: BobbinSpace.step(22))
            BobbinSpeech(
                title: "A stitch spends one from remaining.",
                line: watch.isSpent ? "The spool is Bare. Remaining stays at zero." : "Remaining is live on the glass.",
                figure: BobbinType.figure(watch.remaining),
                maxWidth: BobbinSpace.step(40),
                alignment: .leading,
                lifted: false
            )
            HStack {
                Spacer(minLength: 0)
                BobbinSpeech(
                    title: "Reload fills to capacity and files a mark.",
                    line: watch.reloadEnabled ? "Reload is ready." : "Reload does nothing while remaining equals capacity.",
                    figure: BobbinType.figure(watch.capacity),
                    maxWidth: BobbinSpace.step(30),
                    alignment: .trailing,
                    lifted: false
                )
            }
            VStack(alignment: .leading, spacing: BobbinSpace.step(1)) {
                Text("A stitch at zero writes Bare. Remaining stays at zero.")
                Text("Retract peels the last stitch or the last reload mark.")
            }
            .font(BobbinType.font(.body))
            .foregroundStyle(BobbinPaint.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
            Button {
                if watch.reloadEnabled {
                    watch.reload()
                }
                dismiss()
            } label: {
                Text(watch.reloadEnabled ? "Reload" : "Back to the bobbin")
                    .frame(maxWidth: .infinity, minHeight: BobbinSpace.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(BobbinQuietStyle())
        }
        .padding(.horizontal, BobbinSpace.step(2))
        .padding(.bottom, BobbinSpace.step(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
