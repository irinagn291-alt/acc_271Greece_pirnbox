import SwiftUI

/// Role: ReloadMark. Calendar sheet of days that filed reloads. Empty is a full page.
@MainActor
struct ReloadMarkCalendar: View {
    @Bindable var watch: BobbinWatch
    @Environment(\.dismiss) private var dismiss

    private var days: [BobbinDayFold] {
        Array(watch.document.days.filter { !$0.reloads.isEmpty }.reversed())
    }

    var body: some View {
        VStack(spacing: 0) {
            BobbinSheetBar(title: "Calendar", closeLabel: "Close calendar") {
                dismiss()
            }
            if watch.persistFailed {
                BobbinVacancy(
                    image: BobbinArt.emptyList,
                    headline: "Reload days could not be read.",
                    line: "Retry to load the marks, or close and stitch on the glass.",
                    actionTitle: "Retry",
                    usesAccent: false
                ) {
                    Task { await watch.retryLoad() }
                }
            } else if days.isEmpty {
                BobbinVacancy(
                    image: BobbinArt.emptyList,
                    headline: "No reloads filed.",
                    line: "Reload the bobbin to mark a day.",
                    actionTitle: "Reload",
                    usesAccent: false
                ) {
                    watch.reload()
                    dismiss()
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
            VStack(alignment: .leading, spacing: BobbinSpace.step(1)) {
                Text(BobbinType.figure(days.count))
                    .font(BobbinType.font(.display))
                    .foregroundStyle(BobbinPaint.ink)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(days.count == 1 ? "Day with a reload mark." : "Days with reload marks.")
                    .font(BobbinType.font(.body))
                    .foregroundStyle(BobbinPaint.ink)
            }
            .padding(BobbinSpace.step(2))
            .frame(maxWidth: .infinity, alignment: .leading)
            .bobbinCardSurface()
            .padding(.horizontal, BobbinSpace.step(2))
            List {
                ForEach(days, id: \.dayKey) { fold in
                    VStack(alignment: .leading, spacing: BobbinSpace.step(1)) {
                        Text(BobbinStamp.dayName(fold.dayKey))
                            .font(BobbinType.font(.body))
                            .foregroundStyle(BobbinPaint.ink)
                            .lineLimit(1)
                        Text(reloadLine(fold))
                            .font(BobbinType.font(.quiet))
                            .foregroundStyle(BobbinPaint.muted)
                            .lineLimit(2)
                    }
                    .padding(.vertical, BobbinSpace.step(1))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowBackground(BobbinPaint.surface)
                    .listRowSeparatorTint(BobbinPaint.muted.opacity(0.35))
                }
            }
            .listStyle(.plain)
            .contentMargins(.bottom, BobbinSpace.step(4), for: .scrollContent)
            .scrollContentBackground(.hidden)
            .background(BobbinPaint.background)
        }
        .padding(.top, BobbinSpace.step(1))
    }

    private func reloadLine(_ fold: BobbinDayFold) -> String {
        let count = BobbinType.figure(fold.reloads.count)
        if fold.reloads.count == 1 {
            let before = fold.reloads[0].remainingBefore
            return "One reload. Remaining before was \(BobbinType.figure(before))."
        }
        return "\(count) reloads filed."
    }
}
