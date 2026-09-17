import Foundation

/// Role: Stitch. One unit log. Writes Remaining minus one. The MetricRecord of this bobbin.
struct Stitch: Equatable, Sendable, Identifiable, Hashable, Codable {
    var id: UUID
    var dayKey: Int
    var spentAt: Date
}
