import Foundation

/// Role: Bobbin. Live glass snapshot. Remaining and Capacity are separate integers.
struct Bobbin: Equatable, Sendable {
    var capacity: Capacity
    var remaining: Remaining
    var onboardingComplete: Bool
    var canRetract: Bool

    var stitchEnabled: Bool { true }
    var reloadEnabled: Bool { remaining.units < capacity.units }
    var isSpent: Bool { remaining.isEmpty }
}

enum BobbinSite {
    static let origin = "https://pirnbox-bobbin.pro"
    static let contact = "https://pirnbox-bobbin.pro/contact-us"
    static let userAgent = "Pirnbox/1.0 (iOS; +https://pirnbox-bobbin.pro)"
}
