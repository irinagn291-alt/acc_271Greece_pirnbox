import SwiftUI
import UIKit

/// Role: Bobbin. Locked home. The glass bobbin is the mechanic. Sheets arrive over it.
@MainActor
struct BobbinHome: View {
    @Bindable var watch: BobbinWatch
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        VStack(alignment: .leading, spacing: BobbinSpace.step(2)) {
            header
            if persistMessage != nil {
                errorBanner
            }
            speech
            spoolButton
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            composer
        }
        .padding(.horizontal, BobbinSpace.step(2))
        .padding(.bottom, BobbinSpace.step(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BobbinPaint.background.ignoresSafeArea())
        .sensoryFeedback(.impact(weight: .light), trigger: watch.pulse)
        .sheet(item: $watch.sheet) { sheet in
            sheetBody(sheet)
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $watch.showOnboarding) {
            BobbinOnboarding(
                onContinue: { Task { await watch.finishOnboarding() } },
                onSkip: { Task { await watch.skipOnboarding() } }
            )
            .interactiveDismissDisabled()
        }
        .animation(BobbinSpace.motion(reduce: reduceMotion), value: watch.remaining)
        .animation(BobbinSpace.motion(reduce: reduceMotion), value: watch.sheet)
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            watch.tickDay()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            watch.tickDay()
        }
    }

    private var persistMessage: String? {
        if watch.persistFailed {
            return "The bobbin could not be saved. Retry the last write."
        }
        switch watch.warning {
        case .startedFresh:
            return "The bobbin could not be read. Remaining starts at capacity."
        case .recoveredFromBackup:
            return nil
        case nil:
            return nil
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: BobbinSpace.step(1)) {
            Text("Today's bobbin")
                .font(BobbinType.font(.title))
                .foregroundStyle(BobbinPaint.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text("Tap the glass to spend one unit.")
                .font(BobbinType.font(.body))
                .foregroundStyle(BobbinPaint.ink)
                .fixedSize(horizontal: false, vertical: true)
            if watch.todayStitchCount > 0 {
                Text(todayLine)
                    .font(BobbinType.font(.body))
                    .foregroundStyle(BobbinPaint.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if watch.warning == .recoveredFromBackup {
                Text("Recovered from a backup. Remaining is still on the glass.")
                    .font(BobbinType.font(.body))
                    .foregroundStyle(BobbinPaint.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            crumbs
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, BobbinSpace.step(1))
    }

    private var todayLine: String {
        let count = BobbinType.figure(watch.todayStitchCount)
        if watch.todayStitchCount == 1 {
            return "\(count) stitch on this bobbin today."
        }
        return "\(count) stitches on this bobbin today."
    }

    private var crumbs: some View {
        VStack(alignment: .leading, spacing: BobbinSpace.step(1)) {
            HStack(spacing: BobbinSpace.step(1)) {
                BobbinCrumb(title: "Calendar", symbol: "calendar") {
                    watch.openSheet(.calendar)
                }
                BobbinCrumb(title: "Charts", symbol: "chart.bar") {
                    watch.openSheet(.charts)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: BobbinSpace.step(1)) {
                Spacer(minLength: 0)
                BobbinCrumb(title: "History", symbol: "list.bullet") {
                    watch.openSheet(.history)
                }
                BobbinCrumb(title: "Settings", symbol: "gearshape") {
                    watch.openSheet(.settings)
                }
            }
        }
    }

    private var speech: some View {
        VStack(alignment: .leading, spacing: BobbinSpace.step(1)) {
            BobbinSpeech(
                title: watch.isSpent ? "Bare. Remaining stays at zero." : "Remaining thread on the glass.",
                line: watch.isSpent ? "A tap files Bare. Reload fills the spool." : "Each stitch spends one unit.",
                figure: BobbinType.figure(watch.remaining),
                maxWidth: sizeClass == .regular ? BobbinSpace.step(52) : BobbinSpace.step(35),
                alignment: .leading,
                lifted: false
            )
            HStack {
                Spacer(minLength: 0)
                Button {
                    watch.openSheet(.twist)
                } label: {
                    BobbinSpeech(
                        title: "Capacity",
                        line: "Reload restores this count.",
                        figure: BobbinType.figure(watch.capacity),
                        maxWidth: sizeClass == .regular ? BobbinSpace.step(40) : BobbinSpace.step(32),
                        alignment: .trailing
                    )
                }
                .buttonStyle(BobbinPressStyle())
                .accessibilityLabel("Capacity \(BobbinType.figure(watch.capacity)). Open stitch then reload.")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var spoolButton: some View {
        Button {
            watch.stitch()
        } label: {
            BobbinSpool(
                remaining: watch.remaining,
                capacity: watch.capacity,
                isSpent: watch.isSpent,
                showSuccess: watch.showSuccess
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(BobbinSpoolStyle(loading: watch.showSpinner))
        .disabled(watch.busy)
        .accessibilityLabel("Stitch")
    }

    private var composer: some View {
        HStack(alignment: .center, spacing: BobbinSpace.step(1)) {
            Button {
                watch.reload()
            } label: {
                Text("Reload")
                    .frame(maxWidth: .infinity, minHeight: BobbinSpace.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(BobbinQuietStyle(loading: watch.showSpinner && watch.busy))
            .disabled(watch.busy || !watch.reloadEnabled)
            .accessibilityHint("Restores remaining to capacity and files a reload mark.")

            Button {
                watch.retract()
            } label: {
                Text("Retract")
                    .frame(minWidth: BobbinSpace.tap, minHeight: BobbinSpace.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(BobbinRetractStyle())
            .disabled(watch.busy || !watch.canRetract)
            .accessibilityHint("Peels the last stitch, bare mark, or reload.")
        }
        .frame(maxWidth: .infinity)
    }

    private var errorBanner: some View {
        HStack(alignment: .center, spacing: BobbinSpace.step(1)) {
            VStack(alignment: .leading, spacing: BobbinSpace.step(1)) {
                Text(persistMessage ?? "The bobbin could not be read.")
                    .font(BobbinType.font(.body))
                    .foregroundStyle(BobbinPaint.ink)
                Text("Retry to keep remaining on this device.")
                    .font(BobbinType.font(.quiet))
                    .foregroundStyle(BobbinPaint.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                Task { await watch.retryLoad() }
            } label: {
                Text("Retry")
                    .frame(minWidth: BobbinSpace.tap, minHeight: BobbinSpace.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(BobbinQuietStyle())
        }
        .padding(BobbinSpace.step(2))
        .bobbinCardSurface()
    }

    @ViewBuilder
    private func sheetBody(_ sheet: BobbinSheet) -> some View {
        switch sheet {
        case .calendar:
            CalendarView(watch: watch)
        case .charts:
            ChartsView(watch: watch)
        case .history:
            HistoryView(watch: watch)
        case .settings:
            SettingsView(watch: watch)
        case .twist:
            StitchThenReload(watch: watch)
        }
    }
}
