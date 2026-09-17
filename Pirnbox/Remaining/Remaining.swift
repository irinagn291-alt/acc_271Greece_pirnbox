import Foundation

/// Role: Remaining. Stored thread left on the glass. Starts at Capacity, then lives on its own.
struct Remaining: Equatable, Sendable, Hashable, Codable {
    private(set) var units: Int

    init(units: Int) {
        self.units = max(0, units)
    }

    static func starting(at capacity: Capacity) -> Remaining {
        Remaining(units: capacity.units)
    }

    var isEmpty: Bool { units == 0 }

    mutating func spendOne() -> ThreadSpend {
        guard units > 0 else {
            units = 0
            return .bare
        }
        units -= 1
        return .stitch
    }

    mutating func restoreOne(limit: Capacity) {
        units = min(units + 1, limit.units)
    }

    mutating func fill(to capacity: Capacity) {
        units = capacity.units
    }

    mutating func restore(before remainingBefore: Int) {
        units = max(0, remainingBefore)
    }

    mutating func clamp(to capacity: Capacity) {
        units = min(units, capacity.units)
    }
}

/// Role: Remaining. Result of one spend. A zero spool writes Bare instead of hanging an extra unit.
enum ThreadSpend: Equatable, Sendable {
    case stitch
    case bare
}
