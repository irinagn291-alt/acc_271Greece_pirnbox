import XCTest
@testable import Pirnbox

final class ReviewScreenFlagTests: XCTestCase {
    func test_parsesThreeKeysToThreeDestinations() {
        XCTAssertEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "today"]), .today)
        XCTAssertEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "log"]), .log)
        XCTAssertEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "goals"]), .goals)
        XCTAssertNotEqual(
            ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "today"])?.opens,
            ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "log"])?.opens
        )
        XCTAssertNotEqual(
            ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "log"])?.opens,
            ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "goals"])?.opens
        )
        XCTAssertNotEqual(
            ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "today"])?.opens,
            ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "goals"])?.opens
        )
        XCTAssertEqual(ReviewScreenFlag.today.opens, "home")
        XCTAssertEqual(ReviewScreenFlag.log.opens, "history")
        XCTAssertEqual(ReviewScreenFlag.goals.opens, "settings")
    }

    func test_aliasesHomeHistorySettings() {
        XCTAssertEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "home"]), .today)
        XCTAssertEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "history"]), .log)
        XCTAssertEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "settings"]), .goals)
    }

    func test_consumeReadsOnceAfterOnboarding() {
        var consumed = false
        XCTAssertNil(
            ReviewScreenFlag.consume(
                arguments: ["-ReviewScreen", "log"],
                onboarded: false,
                consumed: &consumed
            )
        )
        XCTAssertFalse(consumed)

        let first = ReviewScreenFlag.consume(
            arguments: ["app", "-ReviewScreen", "log"],
            onboarded: true,
            consumed: &consumed
        )
        XCTAssertEqual(first, .log)
        XCTAssertTrue(consumed)
        XCTAssertNil(
            ReviewScreenFlag.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboarded: true,
                consumed: &consumed
            )
        )
    }

    func test_fromProcessInfo_readsLaunchArgument() {
        XCTAssertEqual(
            ReviewScreenFlag.parse(arguments: ProcessInfo.processInfo.arguments)
                ?? ReviewScreenFlag.fromProcessInfo(),
            ReviewScreenFlag.fromProcessInfo()
        )
    }

    func test_missingOrUnknown_isNil() {
        XCTAssertNil(ReviewScreenFlag.parse(arguments: []))
        XCTAssertNil(ReviewScreenFlag.parse(arguments: ["-ReviewScreen"]))
        XCTAssertNil(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "unknown"]))
        XCTAssertNil(ReviewScreenFlag.parse(arguments: ["today"]))
    }
}
