import XCTest
@testable import Pirnbox

final class BobbinRouteTests: XCTestCase {
    func test_reviewKeysOpenThreeDifferentSurfaces() {
        let today = BobbinRoute.parseReview(arguments: ["-ReviewScreen", "today"])
        let log = BobbinRoute.parseReview(arguments: ["-ReviewScreen", "log"])
        let goals = BobbinRoute.parseReview(arguments: ["-ReviewScreen", "goals"])
        XCTAssertEqual(today, .home)
        XCTAssertEqual(log, .sheet(.history))
        XCTAssertEqual(goals, .sheet(.settings))
        XCTAssertNotEqual(today, log)
        XCTAssertNotEqual(log, goals)
        XCTAssertNotEqual(today, goals)
    }

    func test_reviewAliasesAndExtraSlugs() {
        XCTAssertEqual(BobbinRoute.parseReview(arguments: ["-ReviewScreen", "home"]), .home)
        XCTAssertEqual(BobbinRoute.parseReview(arguments: ["-ReviewScreen", "history"]), .sheet(.history))
        XCTAssertEqual(BobbinRoute.parseReview(arguments: ["-ReviewScreen", "settings"]), .sheet(.settings))
        XCTAssertEqual(BobbinRoute.parseReview(arguments: ["-ReviewScreen", "calendar"]), .sheet(.calendar))
        XCTAssertEqual(BobbinRoute.parseReview(arguments: ["-ReviewScreen", "charts"]), .sheet(.charts))
        XCTAssertEqual(
            BobbinRoute.parseReview(arguments: ["-ReviewScreen", "stitchthenreload"]),
            .sheet(.twist)
        )
    }

    func test_deepLinksOpenFiveSurfaces() {
        XCTAssertEqual(BobbinRoute.parse(URL(string: "pirnbox://home")!), .home)
        XCTAssertEqual(BobbinRoute.parse(URL(string: "pirnbox://calendar")!), .sheet(.calendar))
        XCTAssertEqual(BobbinRoute.parse(URL(string: "pirnbox://charts")!), .sheet(.charts))
        XCTAssertEqual(BobbinRoute.parse(URL(string: "pirnbox://history")!), .sheet(.history))
        XCTAssertEqual(BobbinRoute.parse(URL(string: "pirnbox://settings")!), .sheet(.settings))
        XCTAssertEqual(
            BobbinRoute.parse(URL(string: "https://pirnbox-bobbin.pro/calendar")!),
            .sheet(.calendar)
        )
        XCTAssertEqual(
            BobbinRoute.parse(URL(string: "https://pirnbox-bobbin.pro/charts")!),
            .sheet(.charts)
        )
        XCTAssertNil(BobbinRoute.parse(URL(string: "https://pirnbox-bobbin.pro/contact-us")!))
    }

    @MainActor
    func test_watchAppliesReviewOnceAfterOnboarding() {
        let watch = BobbinWatch(store: BobbinStore(pin: BobbinMemoryPin()), handlesLaunch: false)
        watch.store.markOnboardingComplete()
        watch.showOnboarding = false
        watch.applyReviewOnce(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(watch.sheet, .history)
        watch.applyReviewOnce(arguments: ["-ReviewScreen", "goals"])
        XCTAssertEqual(watch.sheet, .history)
    }
}
