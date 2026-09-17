import XCTest
@testable import Pirnbox

final class BobbinTransportTests: XCTestCase {
    func test_sessionIdentifiesAsPirnbox() {
        let session = BobbinTransport.makeSession()
        let headers = session.configuration.httpAdditionalHeaders
        XCTAssertEqual(headers?["User-Agent"] as? String, BobbinSite.userAgent)
        XCTAssertEqual(
            headers?["User-Agent"] as? String,
            "Pirnbox/1.0 (iOS; +https://pirnbox-bobbin.pro)"
        )
        XCTAssertEqual(session.configuration.timeoutIntervalForRequest, 15)
        XCTAssertEqual(session.configuration.timeoutIntervalForResource, 15)
    }

    func test_retryOnceOnTransportThenStopOn404() {
        XCTAssertTrue(
            BobbinTransport.shouldRetry(
                statusCode: nil,
                urlError: URLError(.timedOut),
                attempt: 0
            )
        )
        XCTAssertFalse(
            BobbinTransport.shouldRetry(
                statusCode: nil,
                urlError: URLError(.timedOut),
                attempt: 1
            )
        )
        XCTAssertFalse(
            BobbinTransport.shouldRetry(statusCode: 404, urlError: nil, attempt: 0)
        )
        XCTAssertTrue(
            BobbinTransport.shouldRetry(statusCode: 500, urlError: nil, attempt: 0)
        )
        XCTAssertEqual(BobbinTransport.fault(statusCode: 404, urlError: nil), .notFound)
        XCTAssertEqual(
            BobbinTransport.fault(statusCode: nil, urlError: URLError(.timedOut)),
            .timeout
        )
    }

    func test_fetchReadsLocalFileWithoutRemoteCatalog() async throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent("ping.json")
        try Data(#"{"ok":true}"#.utf8).write(to: url, options: .atomic)
        let transport = BobbinTransport(session: BobbinTransport.makeSession())
        let data = try await transport.data(from: url)
        XCTAssertEqual(String(data: data, encoding: .utf8), #"{"ok":true}"#)
        try? FileManager.default.removeItem(at: folder)
    }
}
