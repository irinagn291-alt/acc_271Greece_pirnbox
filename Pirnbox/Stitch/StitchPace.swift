import Foundation

/// Role: Stitch. OLS stitches per day versus day. COSC holds when every |dev| is at most 4.
enum StitchPace {
    static let COSCAbsDevLimit = 4

    struct Fit: Equatable, Sendable {
        var slopePerDay: Double
        var intercept: Double
        var rSquared: Double
        var deviations: [Double]

        var meetsCOSC: Bool {
            deviations.allSatisfy { abs($0) <= Double(StitchPace.COSCAbsDevLimit) }
        }
    }

    static func OLS(dayOffsets: [Double], stitches: [Double]) -> Fit? {
        guard dayOffsets.count == stitches.count, dayOffsets.count >= 2 else {
            return nil
        }
        let count = Double(dayOffsets.count)
        let meanX = dayOffsets.reduce(0, +) / count
        let meanY = stitches.reduce(0, +) / count
        var sumXX = 0.0
        var sumXY = 0.0
        for (x, y) in zip(dayOffsets, stitches) {
            let dx = x - meanX
            sumXX += dx * dx
            sumXY += dx * (y - meanY)
        }
        let slope: Double
        let intercept: Double
        if sumXX == 0 {
            slope = 0
            intercept = meanY
        } else {
            slope = sumXY / sumXX
            intercept = meanY - slope * meanX
        }
        var ssRes = 0.0
        var ssTot = 0.0
        var deviations: [Double] = []
        deviations.reserveCapacity(stitches.count)
        for (x, y) in zip(dayOffsets, stitches) {
            let predicted = intercept + slope * x
            let deviation = y - predicted
            deviations.append(deviation)
            ssRes += deviation * deviation
            let dy = y - meanY
            ssTot += dy * dy
        }
        let rSquared: Double
        if ssTot == 0 {
            rSquared = 1
        } else {
            rSquared = max(0, 1 - ssRes / ssTot)
        }
        return Fit(
            slopePerDay: slope,
            intercept: intercept,
            rSquared: rSquared,
            deviations: deviations
        )
    }

    static func OLS(days: [BobbinDayFold], calendar: Calendar = .current) -> Fit? {
        let used = days.filter { !$0.stitches.isEmpty }.sorted { $0.dayKey < $1.dayKey }
        guard used.count >= 2 else { return nil }
        let origin = BobbinStamp.date(from: used[0].dayKey, calendar: calendar)
        let offsets = used.map { fold in
            BobbinStamp.date(from: fold.dayKey, calendar: calendar).timeIntervalSince(origin) / 86_400
        }
        let stitches = used.map { Double($0.stitches.count) }
        return OLS(dayOffsets: offsets, stitches: stitches)
    }
}
