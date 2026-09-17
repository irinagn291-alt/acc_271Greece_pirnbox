import Foundation

/// Role: Capacity. Integer spool size. Remaining is a separate stored field and is never this value.
struct Capacity: Equatable, Sendable, Hashable, Codable {
    var units: Int

    static let origin = Capacity(units: 12)

    init(units: Int) {
        self.units = units
    }

    func clamp(_ remaining: Remaining) -> Remaining {
        Remaining(units: min(remaining.units, units))
    }
}
