import Foundation

/// Role: ReloadMark. Files remainingBefore and sets Remaining back to Capacity.
struct ReloadMark: Equatable, Sendable, Identifiable, Hashable, Codable {
    var id: UUID
    var dayKey: Int
    var remainingBefore: Int
    var filedAt: Date
}
