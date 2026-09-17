import XCTest
@testable import Pirnbox

/// Family metric_capacity invariant: one unit log, capacity formula, calendar.
final class FamilyInvariantTests: XCTestCase {
    private let calendar = BobbinTestDates.calendar()

    func test_oneUnitLog_capacityFormula_calendar() {
        var document = BobbinDocument.fresh(capacity: 8)
        let today = BobbinTestDates.day(2026, 9, 17, calendar: calendar)
        XCTAssertEqual(document.capacity, 8)
        XCTAssertEqual(document.remaining, 8)
        XCTAssertEqual(document.remaining, document.capacity)

        let kind = document.stitch(at: today, calendar: calendar)
        XCTAssertEqual(kind, .stitch)
        XCTAssertEqual(document.remaining, 7)
        XCTAssertEqual(document.capacity, 8)
        XCTAssertNotEqual(document.remaining, document.capacity)
        XCTAssertEqual(document.stitchCount(on: BobbinDay.key(from: today, calendar: calendar)), 1)
        XCTAssertEqual(document.writes.count, 1)

        document.reload(at: today, calendar: calendar)
        XCTAssertEqual(document.remaining, document.capacity)
        let dayKey = BobbinDay.key(from: today, calendar: calendar)
        XCTAssertEqual(document.reloadDayKeys, [dayKey])
        XCTAssertEqual(document.fold(on: dayKey).reloads.first?.remainingBefore, 7)

        let next = BobbinTestDates.day(2026, 9, 18, calendar: calendar)
        document.stitch(at: next, calendar: calendar)
        document.reload(at: next, calendar: calendar)
        XCTAssertEqual(document.reloadDayKeys.count, 2)
        XCTAssertEqual(BobbinDay.key(from: today, calendar: calendar), 2026_09_17)
        XCTAssertEqual(BobbinDay.key(from: next, calendar: calendar), 2026_09_18)
    }

    func test_remainingNeverGoesNegative() {
        var document = BobbinDocument.fresh(capacity: 2)
        let today = BobbinTestDates.day(2026, 9, 17, calendar: calendar)
        for _ in 0 ..< 6 {
            document.stitch(at: today, calendar: calendar)
            XCTAssertGreaterThanOrEqual(document.remaining, 0)
        }
        XCTAssertEqual(document.remaining, 0)
        XCTAssertEqual(document.fold(on: 2026_09_17).stitches.count, 2)
        XCTAssertEqual(document.fold(on: 2026_09_17).bares.count, 4)
    }

    func test_OLS_stitchPace_COSC_absDevLimit() {
        XCTAssertEqual(StitchPace.COSCAbsDevLimit, 4)

        let line = StitchPace.OLS(dayOffsets: [0, 1, 2], stitches: [1, 3, 5])
        XCTAssertEqual(line?.slopePerDay ?? 0, 2, accuracy: 0.000_1)
        XCTAssertEqual(line?.intercept ?? 0, 1, accuracy: 0.000_1)
        XCTAssertEqual(line?.rSquared ?? 0, 1, accuracy: 0.000_1)
        XCTAssertEqual(line?.meetsCOSC, true)

        let miss = StitchPace.OLS(dayOffsets: [0, 1, 2], stitches: [0, 0, 20])
        XCTAssertEqual(miss?.meetsCOSC, false)
        XCTAssertGreaterThan(miss?.deviations.map(abs).max() ?? 0, 4)

        var document = BobbinDocument.fresh(capacity: 12)
        let first = BobbinTestDates.day(2026, 9, 17, calendar: calendar)
        let second = BobbinTestDates.day(2026, 9, 18, calendar: calendar)
        document.stitch(at: first, calendar: calendar)
        document.stitch(at: second, calendar: calendar)
        document.stitch(at: second, calendar: calendar)
        let fit = StitchPace.OLS(days: document.days, calendar: calendar)
        XCTAssertEqual(fit?.slopePerDay ?? 0, 1, accuracy: 0.000_1)
        XCTAssertEqual(fit?.meetsCOSC, true)
        XCTAssertNotNil(fit, "OLS s/day vs day; COSC |dev|<=4")
    }
}
