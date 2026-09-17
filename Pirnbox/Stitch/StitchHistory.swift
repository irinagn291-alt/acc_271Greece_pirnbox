import SwiftUI

/// Role: Stitch. History sheet of Stitch order, Bare, and ReloadMarks. ReviewScreen log.
@MainActor
struct StitchHistory: View {
    @Bindable var watch: BobbinWatch
    @Environment(\.dismiss) private var dismiss

    private var rows: [HistoryRow] {
        Array(watch.document.writes.reversed()).compactMap { write in
            HistoryRow(write: write, fold: watch.document.fold(on: write.dayKey))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            BobbinSheetBar(title: "History", closeLabel: "Close history") {
                dismiss()
            }
            if watch.persistFailed {
                BobbinVacancy(
                    image: BobbinArt.emptyList,
                    headline: "History could not be read.",
                    line: "Retry to load stitches, bare marks, and reloads.",
                    actionTitle: "Retry",
                    usesAccent: false
                ) {
                    Task { await watch.retryLoad() }
                }
            } else if rows.isEmpty {
                BobbinVacancy(
                    image: BobbinArt.emptyList,
                    headline: "Nothing stitched yet.",
                    line: "Tap the bobbin to spend a unit.",
                    actionTitle: "Stitch",
                    usesAccent: true
                ) {
                    watch.stitch()
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
                Text(BobbinType.figure(rows.count))
                    .font(BobbinType.font(.display))
                    .foregroundStyle(BobbinPaint.ink)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(rows.count == 1 ? "Write on this bobbin." : "Writes on this bobbin.")
                    .font(BobbinType.font(.body))
                    .foregroundStyle(BobbinPaint.ink)
            }
            .padding(BobbinSpace.step(2))
            .frame(maxWidth: .infinity, alignment: .leading)
            .bobbinCardSurface()
            .padding(.horizontal, BobbinSpace.step(2))
            List {
                ForEach(rows) { row in
                    VStack(alignment: .leading, spacing: BobbinSpace.step(1)) {
                        Text(row.title)
                            .font(BobbinType.font(.body))
                            .foregroundStyle(BobbinPaint.ink)
                            .lineLimit(1)
                        Text(row.line)
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
}

/// Role: Stitch. One history row. Identity is the write id.
struct HistoryRow: Identifiable {
    var id: UUID
    var title: String
    var line: String

    init?(write: BobbinWrite, fold: BobbinDayFold) {
        id = write.id
        let day = BobbinStamp.dayName(write.dayKey)
        switch write.kind {
        case .stitch:
            guard let stitch = fold.stitches.first(where: { $0.id == write.id }) else { return nil }
            title = "Stitch"
            line = "\(day), \(BobbinStamp.clock(stitch.spentAt)). Spent one unit."
        case .bare:
            guard let bare = fold.bares.first(where: { $0.id == write.id }) else { return nil }
            title = "Bare"
            line = "\(day), \(BobbinStamp.clock(bare.markedAt)). Remaining stayed at zero."
        case .reload:
            guard let mark = fold.reloads.first(where: { $0.id == write.id }) else { return nil }
            title = "Reload"
            line = "\(day), \(BobbinStamp.clock(mark.filedAt)). Remaining before was \(BobbinType.figure(mark.remainingBefore))."
        }
    }
}
