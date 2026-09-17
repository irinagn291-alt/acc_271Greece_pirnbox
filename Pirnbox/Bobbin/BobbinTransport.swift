import Foundation

/// Role: leftover transport. The bobbin is local; this client is idle until a later surface needs it.
enum BobbinTransportError: Error, Equatable, Sendable {
    case timeout
    case transport
    case notFound
    case decoding
    case cancelled
}

struct BobbinTransport {
    static let userAgent = BobbinSite.userAgent
    static let timeout: TimeInterval = 15

    private let session: URLSession

    init(session: URLSession = BobbinTransport.makeSession()) {
        self.session = session
    }

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        configuration.httpAdditionalHeaders = ["User-Agent": userAgent]
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }

    static func shouldRetry(statusCode: Int?, urlError: URLError?, attempt: Int) -> Bool {
        if attempt >= 1 { return false }
        if statusCode == 404 { return false }
        if let statusCode, (400 ..< 500).contains(statusCode) { return false }
        if urlError != nil { return true }
        if let statusCode, statusCode >= 500 { return true }
        return false
    }

    static func fault(statusCode: Int?, urlError: URLError?) -> BobbinTransportError {
        if statusCode == 404 { return .notFound }
        if urlError?.code == .timedOut { return .timeout }
        if urlError?.code == .cancelled { return .cancelled }
        return .transport
    }

    func data(from url: URL) async throws -> Data {
        var attempt = 0
        while true {
            try Task.checkCancellation()
            do {
                let (data, response) = try await session.data(from: url)
                if let http = response as? HTTPURLResponse {
                    if http.statusCode == 404 {
                        throw BobbinTransportError.notFound
                    }
                    if Self.shouldRetry(statusCode: http.statusCode, urlError: nil, attempt: attempt) {
                        attempt += 1
                        continue
                    }
                    if !(200 ..< 300).contains(http.statusCode) {
                        throw BobbinTransportError.transport
                    }
                }
                return data
            } catch is CancellationError {
                throw BobbinTransportError.cancelled
            } catch let error as BobbinTransportError {
                throw error
            } catch let urlError as URLError {
                if urlError.code == .cancelled {
                    throw BobbinTransportError.cancelled
                }
                if Self.shouldRetry(statusCode: nil, urlError: urlError, attempt: attempt) {
                    attempt += 1
                    continue
                }
                throw Self.fault(statusCode: nil, urlError: urlError)
            } catch {
                throw BobbinTransportError.transport
            }
        }
    }
}
