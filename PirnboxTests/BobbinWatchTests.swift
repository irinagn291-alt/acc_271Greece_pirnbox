import XCTest
@testable import Pirnbox

/// Presentation seam: views call stitch, reload, and retract on BobbinWatch.
@MainActor
final class BobbinWatchTests: XCTestCase {
    private let calendar = BobbinTestDates.calendar()
    private lazy var today = BobbinTestDates.day(2026, 9, 17, calendar: calendar)

    func test_stitchReloadRetractGoThroughWatch() {
        let watch = makeWatch()
        XCTAssertEqual(watch.remaining, watch.capacity)
        XCTAssertTrue(watch.stitchEnabled)
        XCTAssertFalse(watch.reloadEnabled)

        watch.stitch()
        XCTAssertEqual(watch.remaining, watch.capacity - 1)
        XCTAssertTrue(watch.reloadEnabled)
        XCTAssertGreaterThan(watch.pulse, 0)

        let afterStitch = watch.pulse
        watch.reload()
        XCTAssertEqual(watch.remaining, watch.capacity)
        XCTAssertFalse(watch.reloadEnabled)
        XCTAssertGreaterThan(watch.pulse, afterStitch)

        watch.stitch()
        watch.retract()
        XCTAssertEqual(watch.remaining, watch.capacity)
        XCTAssertTrue(watch.canRetract)
    }

    func test_bareAtZeroLeavesRemainingAtZero() {
        let watch = makeWatch(capacity: 1)
        watch.stitch()
        XCTAssertEqual(watch.remaining, 0)
        XCTAssertTrue(watch.isSpent)
        watch.stitch()
        XCTAssertEqual(watch.remaining, 0)
        XCTAssertEqual(watch.document.fold(on: 2026_09_17).bares.count, 1)
        watch.retract()
        XCTAssertEqual(watch.remaining, 0)
        XCTAssertTrue(watch.document.fold(on: 2026_09_17).bares.isEmpty)
    }

    func test_homeNeverLeaves_sheetsCoverTheFourSurfaces() {
        let watch = makeWatch()
        watch.store.markOnboardingComplete()
        watch.showOnboarding = false

        watch.openSheet(.calendar)
        XCTAssertEqual(watch.sheet, .calendar)
        watch.openSheet(.charts)
        XCTAssertEqual(watch.sheet, .charts)
        watch.openSheet(.history)
        XCTAssertEqual(watch.sheet, .history)
        watch.openSheet(.settings)
        XCTAssertEqual(watch.sheet, .settings)
        watch.open(.home)
        XCTAssertNil(watch.sheet)
        watch.openSheet(.twist)
        XCTAssertEqual(watch.sheet, .twist)
        watch.dismissSheet()
        XCTAssertNil(watch.sheet)
    }

    func test_deepLinkHomeDismissesSheet() {
        let watch = makeWatch()
        watch.store.markOnboardingComplete()
        watch.showOnboarding = false
        watch.open(url: URL(string: "pirnbox://history")!)
        XCTAssertEqual(watch.sheet, .history)
        watch.open(url: URL(string: "pirnbox://home")!)
        XCTAssertNil(watch.sheet)
        watch.open(url: URL(string: "https://pirnbox-bobbin.pro/settings")!)
        XCTAssertEqual(watch.sheet, .settings)
    }

    func test_reviewIsDeferredUntilOnboardingEnds() async {
        let watch = makeWatch()
        watch.showOnboarding = true
        watch.open(.sheet(.history))
        XCTAssertNil(watch.sheet)
        await watch.finishOnboarding()
        XCTAssertFalse(watch.showOnboarding)
        XCTAssertEqual(watch.sheet, .history)
    }

    func test_tickDayRefreshesDayKey() {
        let watch = makeWatch()
        watch.tickDay()
        XCTAssertEqual(watch.dayKey, BobbinDay.key(from: Date(), calendar: .current))
    }

    private func makeWatch(capacity: Int = 12) -> BobbinWatch {
        let store = BobbinStore(
            pin: BobbinMemoryPin(),
            calendar: calendar,
            now: { [today] in today }
        )
        if capacity != store.document.capacity {
            try? store.setCapacity(capacity)
        }
        return BobbinWatch(store: store, handlesLaunch: false)
    }
}
