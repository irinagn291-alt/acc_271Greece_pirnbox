import Foundation

/// Role: Bobbin. Sheet crumbs over the locked glass. Home never leaves.
enum BobbinSheet: String, Identifiable, Equatable, Sendable, CaseIterable {
    case calendar
    case charts
    case history
    case settings
    case twist

    var id: String { rawValue }
}

/// Role: Bobbin. Deep links, App Intents, and ReviewScreen keys. Home dismisses sheets.
enum BobbinRoute: Equatable, Sendable {
    case home
    case sheet(BobbinSheet)

    var sheet: BobbinSheet? {
        switch self {
        case .home: nil
        case .sheet(let sheet): sheet
        }
    }

    static func fromReview(_ flag: ReviewScreenFlag) -> BobbinRoute {
        switch flag {
        case .today: .home
        case .log: .sheet(.history)
        case .goals: .sheet(.settings)
        }
    }

    static func parseReview(arguments: [String]) -> BobbinRoute? {
        if let flag = ReviewScreenFlag.parse(arguments: arguments) {
            return fromReview(flag)
        }
        guard let index = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = index + 1
        guard next < arguments.count else { return nil }
        return interpret(token: arguments[next])
    }

    static func parse(_ url: URL) -> BobbinRoute? {
        let scheme = url.scheme?.lowercased() ?? ""
        let host = url.host?.lowercased() ?? ""
        let parts = url.pathComponents.filter { $0 != "/" }

        if scheme == "pirnbox" {
            let token = host.isEmpty ? (parts.first?.lowercased() ?? "home") : host
            return interpret(token: token)
        }
        if scheme == "https" || scheme == "http" {
            guard host == "pirnbox-bobbin.pro" || host == "www.pirnbox-bobbin.pro" else {
                return nil
            }
            let token = parts.first?.lowercased() ?? "home"
            if token == "contact-us" { return nil }
            return interpret(token: token)
        }
        return nil
    }

    static func interpret(token: String) -> BobbinRoute? {
        switch token.lowercased() {
        case "", "home", "today", "bobbin":
            return .home
        case "calendar":
            return .sheet(.calendar)
        case "charts", "chart":
            return .sheet(.charts)
        case "history", "log":
            return .sheet(.history)
        case "settings", "goals":
            return .sheet(.settings)
        case "twist", "stitchthenreload":
            return .sheet(.twist)
        default:
            return nil
        }
    }
}

extension BobbinSite {
    static let contactURL = URL(string: "https://pirnbox-bobbin.pro/contact-us")!
}
