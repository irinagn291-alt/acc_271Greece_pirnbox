import Charts
import SwiftUI

/// Role: Stitch. Charts sheet. Stitch counts versus Capacity. Stock Chart only.
@MainActor
struct StitchCharts: View {
    @Bindable var watch: BobbinWatch
    @Environment(\.dismiss) private var dismiss

    private var rows: [StitchChartRow] {
        watch.document.days
            .filter { !$0.stitches.isEmpty }
            .map { fold in
                StitchChartRow(
                    dayKey: fold.dayKey,
                    label: BobbinStamp.dayName(fold.dayKey),
                    stitches: fold.stitches.count
                )
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            BobbinSheetBar(title: "Charts", closeLabel: "Close charts") {
                dismiss()
            }
            if watch.persistFailed {
                BobbinVacancy(
                    image: BobbinArt.emptyList,
                    headline: "Charts could not be read.",
                    line: "Retry to load stitch counts against capacity.",
                    actionTitle: "Retry",
                    usesAccent: false
                ) {
                    Task { await watch.retryLoad() }
                }
            } else if rows.isEmpty {
                BobbinVacancy(
                    image: BobbinArt.emptyList,
                    headline: "No stitches to chart.",
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
                Text(BobbinType.figure(totalStitches))
                    .font(BobbinType.font(.display))
                    .foregroundStyle(BobbinPaint.ink)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text("Stitches versus capacity \(BobbinType.figure(watch.capacity)).")
                    .font(BobbinType.font(.body))
                    .foregroundStyle(BobbinPaint.ink)
            }
            .padding(BobbinSpace.step(2))
            .frame(maxWidth: .infinity, alignment: .leading)
            .bobbinCardSurface()
            Chart {
                ForEach(rows) { row in
                    BarMark(
                        x: .value("Day", row.label),
                        y: .value("Stitches", row.stitches)
                    )
                    .foregroundStyle(BobbinPaint.accent)
                    .cornerRadius(BobbinRound.chip)
                }
                RuleMark(y: .value("Capacity", watch.capacity))
                    .foregroundStyle(BobbinPaint.ink.opacity(0.45))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [BobbinSpace.unit, BobbinSpace.unit]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Capacity")
                            .font(BobbinType.font(.caption))
                            .foregroundStyle(BobbinPaint.ink)
                    }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, BobbinSpace.step(2))
            .padding(.bottom, BobbinSpace.step(2))
        }
        .padding(.top, BobbinSpace.step(1))
    }

    private var totalStitches: Int {
        rows.reduce(0) { $0 + $1.stitches }
    }
}

/// Role: Stitch. One day on the chart. Identity is the day key, never an index.
struct StitchChartRow: Identifiable, Equatable {
    var dayKey: Int
    var label: String
    var stitches: Int
    var id: Int { dayKey }
}
