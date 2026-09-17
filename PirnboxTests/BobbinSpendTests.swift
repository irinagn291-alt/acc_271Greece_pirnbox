import XCTest
@testable import Pirnbox

final class BobbinSpendTests: XCTestCase {
    private let calendar = BobbinTestDates.calendar()
    private lazy var today = BobbinTestDates.day(2026, 9, 17, calendar: calendar)

    func test_primaryVerbEmptyPopulatedInvalid() throws {
        var document = BobbinDocument.fresh(capacity: 4)
        XCTAssertEqual(document.remaining, 4)
        XCTAssertTrue(document.writes.isEmpty)
        XCTAssertEqual(document.stitch(at: today, calendar: calendar), .stitch)
        XCTAssertEqual(document.remaining, 3)
        XCTAssertEqual(document.writes.count, 1)

        XCTAssertThrowsError(try document.setCapacity(0)) { error in
            XCTAssertEqual(error as? BobbinFault, .invalidCapacity)
        }
        XCTAssertEqual(document.capacity, 4)
        XCTAssertEqual(document.remaining, 3)
        var empty = BobbinDocument.fresh()
        XCTAssertNil(empty.retract())
    }

    func test_stitchSpendsOneAndFloorsAtZero() {
        var document = BobbinDocument.fresh(capacity: 2)
        XCTAssertEqual(document.stitch(at: today, calendar: calendar), .stitch)
        XCTAssertEqual(document.remaining, 1)
        XCTAssertEqual(document.stitch(at: today, calendar: calendar), .stitch)
        XCTAssertEqual(document.remaining, 0)
        XCTAssertEqual(document.stitch(at: today, calendar: calendar), .bare)
        XCTAssertEqual(document.remaining, 0)
        XCTAssertEqual(document.fold(on: 2026_09_17).bares.count, 1)
    }

    func test_reloadRestoresRemainingAndNoOpAtFull() {
        var document = BobbinDocument.fresh(capacity: 5)
        XCTAssertFalse(document.reload(at: today, calendar: calendar))
        XCTAssertTrue(document.writes.isEmpty)

        document.stitch(at: today, calendar: calendar)
        document.stitch(at: today, calendar: calendar)
        XCTAssertTrue(document.reload(at: today, calendar: calendar))
        XCTAssertEqual(document.remaining, 5)
        XCTAssertEqual(document.fold(on: 2026_09_17).reloads.first?.remainingBefore, 3)
        XCTAssertFalse(document.reload(at: today, calendar: calendar))
        XCTAssertEqual(document.fold(on: 2026_09_17).reloads.count, 1)
    }

    func test_retractRestoresStitchReloadAndBare() {
        var document = BobbinDocument.fresh(capacity: 3)
        document.stitch(at: today, calendar: calendar)
        document.stitch(at: today, calendar: calendar)
        document.stitch(at: today, calendar: calendar)
        XCTAssertEqual(document.remaining, 0)
        XCTAssertEqual(document.stitch(at: today, calendar: calendar), .bare)
        XCTAssertEqual(document.retract(), .bare)
        XCTAssertEqual(document.remaining, 0)
        XCTAssertEqual(document.retract(), .stitch)
        XCTAssertEqual(document.remaining, 1)

        document.reload(at: today, calendar: calendar)
        XCTAssertEqual(document.remaining, 3)
        XCTAssertEqual(document.retract(), .reload)
        XCTAssertEqual(document.remaining, 1)
    }

    func test_capacityEditClampsRemainingAndDoesNotAutofill() throws {
        var document = BobbinDocument.fresh(capacity: 10)
        document.stitch(at: today, calendar: calendar)
        document.stitch(at: today, calendar: calendar)
        try document.setCapacity(5)
        XCTAssertEqual(document.capacity, 5)
        XCTAssertEqual(document.remaining, 5)
        try document.setCapacity(12)
        XCTAssertEqual(document.capacity, 12)
        XCTAssertEqual(document.remaining, 5)
    }

    func test_remainingIsStoredSeparatelyFromCapacity() throws {
        var document = BobbinDocument.fresh(capacity: 12)
        document.stitch(at: today, calendar: calendar)
        let data = try BobbinCodec.encode(document)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["schemaVersion"] as? Int, 1)
        XCTAssertEqual(object["capacity"] as? Int, 12)
        XCTAssertEqual(object["remaining"] as? Int, 11)
        XCTAssertNotEqual(object["remaining"] as? Int, object["capacity"] as? Int)
    }

    @MainActor
    func test_storeOwnsTheFold() async {
        let moment = today
        let store = BobbinStore(pin: BobbinMemoryPin(), calendar: calendar, now: { moment })
        XCTAssertTrue(store.bobbin.stitchEnabled)
        store.stitch(at: today)
        store.stitch(at: today)
        XCTAssertEqual(store.document.remaining, 10)
        store.reload(at: today)
        XCTAssertEqual(store.document.remaining, 12)
        store.retract()
        XCTAssertEqual(store.document.remaining, 10)
    }

    func test_seedFillsHistoryCalendarAndLeavesStitchEnabled() {
        let document = BobbinSeed.document(now: today, calendar: calendar)
        XCTAssertTrue(document.onboardingComplete)
        XCTAssertEqual(document.capacity, 12)
        XCTAssertEqual(document.remaining, 7)
        XCTAssertTrue(document.remaining > 0)
        XCTAssertTrue(document.remaining < document.capacity)
        XCTAssertGreaterThan(document.reloadDayKeys.count, 1)
        XCTAssertGreaterThan(document.writes.count, 8)
        XCTAssertFalse(document.writes.contains { $0.kind == .bare })
        XCTAssertTrue(document.snapshot.stitchEnabled)
    }
}
