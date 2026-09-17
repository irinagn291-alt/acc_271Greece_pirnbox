import XCTest
@testable import Pirnbox

final class PirnboxTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: PirnboxApp.self), "PirnboxApp")
    }
}
