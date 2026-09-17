import XCTest
@testable import Pirnbox

final class BobbinVaultTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!
    private let calendar = BobbinTestDates.calendar()
    private lazy var today = BobbinTestDates.day(2026, 9, 17, calendar: calendar)

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        suiteName = "pnb.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        defaults = nil
        suiteName = nil
    }

    func test_roundTripWriteRelaunchReload() async throws {
        let vault = makeVault()
        var document = BobbinDocument.fresh(capacity: 12)
        document.stitch(at: today, calendar: calendar)
        document.stitch(at: today, calendar: calendar)
        document.reload(at: today, calendar: calendar)
        document.onboardingComplete = true
        try await vault.commit(document)

        let relaunched = makeVault()
        let recalled = await relaunched.recall()
        XCTAssertNil(recalled.warning)
        XCTAssertEqual(recalled.document.capacity, 12)
        XCTAssertEqual(recalled.document.remaining, 12)
        XCTAssertEqual(recalled.document.fold(on: 2026_09_17).stitches.count, 2)
        XCTAssertEqual(recalled.document.fold(on: 2026_09_17).reloads.count, 1)
        XCTAssertEqual(recalled.document.fold(on: 2026_09_17).reloads.first?.remainingBefore, 10)
        XCTAssertTrue(recalled.document.onboardingComplete)
        XCTAssertNotNil(defaults.data(forKey: BobbinKeys.bobbin))
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: directory.appendingPathComponent("bobbin.json").path)
        )
    }

    func test_corruptFileFallsBackToBackup() async throws {
        let vault = makeVault()
        var document = BobbinDocument.fresh(capacity: 8)
        document.stitch(at: today, calendar: calendar)
        try await vault.commit(document)
        if let good = defaults.data(forKey: BobbinKeys.bobbin) {
            defaults.set(good, forKey: BobbinKeys.backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: BobbinKeys.bobbin)
        try Data("{not-json".utf8).write(to: directory.appendingPathComponent("bobbin.json"))

        let recalled = await makeVault().recall()
        XCTAssertEqual(recalled.warning, .recoveredFromBackup)
        XCTAssertEqual(recalled.document.remaining, 7)
        XCTAssertEqual(recalled.document.capacity, 8)
    }

    func test_corruptWithoutBackupStartsFreshRemainingAtCapacity() async throws {
        defaults.set(Data("nope".utf8), forKey: BobbinKeys.bobbin)
        let recalled = await makeVault().recall()
        XCTAssertEqual(recalled.warning, .startedFresh)
        XCTAssertEqual(recalled.document.remaining, Capacity.origin.units)
        XCTAssertEqual(recalled.document.remaining, recalled.document.capacity)
        XCTAssertTrue(recalled.document.writes.isEmpty)
        XCTAssertEqual(defaults.data(forKey: BobbinKeys.bobbin), Data("nope".utf8))
    }

    func test_unknownSchemaIsRecoverable() async throws {
        let payload = Data(#"{"schemaVersion":99,"capacity":8,"remaining":8}"#.utf8)
        defaults.set(payload, forKey: BobbinKeys.bobbin)
        let recalled = await makeVault().recall()
        XCTAssertEqual(recalled.warning, .startedFresh)
        XCTAssertEqual(recalled.document.remaining, Capacity.origin.units)
    }

    func test_resetAllDataClearsProjection() async throws {
        let vault = makeVault()
        var document = BobbinSeed.document(now: today, calendar: calendar)
        document.stitch(at: today, calendar: calendar)
        try await vault.commit(document)
        await vault.markDemoPlanted()
        try await vault.wipe()
        let recalled = await vault.recall()
        XCTAssertEqual(recalled.document.remaining, recalled.document.capacity)
        XCTAssertTrue(recalled.document.writes.isEmpty)
        XCTAssertNil(defaults.data(forKey: BobbinKeys.bobbin))
        let planted = await vault.demoPlanted()
        XCTAssertFalse(planted)
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: directory.appendingPathComponent("bobbin.json").path)
        )
    }

    @MainActor
    func test_storeFlushRoundTrip() async throws {
        let vault = makeVault(delay: 0)
        let moment = today
        let store = BobbinStore(pin: vault, calendar: calendar, now: { moment })
        await store.load()
        store.stitch(at: today)
        store.stitch(at: today)
        await store.flush()

        let storeAgain = BobbinStore(pin: makeVault(delay: 0), calendar: calendar, now: { moment })
        await storeAgain.load()
        XCTAssertEqual(storeAgain.document.remaining, 10)
        XCTAssertEqual(storeAgain.document.writes.count, 2)
    }

    private func makeVault(delay: UInt64 = 0) -> BobbinVault {
        BobbinVault(
            directory: directory,
            suiteName: suiteName,
            writeDelayNanoseconds: delay
        )
    }
}
