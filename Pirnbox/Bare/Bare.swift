import Foundation

/// Role: Bare. A Stitch while Remaining is already zero. Remaining stays at zero.
struct Bare: Equatable, Sendable, Identifiable, Hashable, Codable {
    var id: UUID
    var dayKey: Int
    var markedAt: Date
}
