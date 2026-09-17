import Foundation

/// Launch argument `-ReviewScreen today|log|goals` read once after onboarding.
/// today opens Home, log opens History, goals opens Settings.
enum ReviewScreenFlag: String, Equatable, Sendable {
    case today
    case log
    case goals

    var opens: String {
        switch self {
        case .today: "home"
        case .log: "history"
        case .goals: "settings"
        }
    }

    static func fromProcessInfo() -> ReviewScreenFlag? {
        parse(arguments: ProcessInfo.processInfo.arguments)
    }

    static func parse(arguments: [String]) -> ReviewScreenFlag? {
        guard let index = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = index + 1
        guard next < arguments.count else { return nil }
        switch arguments[next].lowercased() {
        case Self.today.rawValue, "home":
            return .today
        case Self.log.rawValue, "history":
            return .log
        case Self.goals.rawValue, "settings":
            return .goals
        default:
            return nil
        }
    }

    static func consume(
        arguments: [String],
        onboarded: Bool,
        consumed: inout Bool
    ) -> ReviewScreenFlag? {
        guard onboarded, !consumed else { return nil }
        consumed = true
        return parse(arguments: arguments)
    }
}
