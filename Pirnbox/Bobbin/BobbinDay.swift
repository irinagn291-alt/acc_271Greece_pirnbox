import Foundation

/// Role: Bobbin. Day identity as Int YYYYMMDD from Calendar.startOfDay, never a Date dictionary key.
enum BobbinDay {
    static func key(from date: Date, calendar: Calendar) -> Int {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 1970
        let month = parts.month ?? 1
        let day = parts.day ?? 1
        return year * 10_000 + month * 100 + day
    }
}

/// Role: Bobbin. Per-day fold of Stitch, Bare, and ReloadMark.
struct BobbinDayFold: Equatable, Sendable, Codable {
    var dayKey: Int
    var stitches: [Stitch]
    var bares: [Bare]
    var reloads: [ReloadMark]

    var isEmpty: Bool {
        stitches.isEmpty && bares.isEmpty && reloads.isEmpty
    }
}

/// Role: Bobbin. Ordered peel stack. Retract pops the last write on this bobbin.
struct BobbinWrite: Equatable, Sendable, Identifiable, Codable {
    var id: UUID
    var kind: BobbinWriteKind
    var dayKey: Int
}

/// Role: Bobbin. Kind of the last persisted verb.
enum BobbinWriteKind: String, Equatable, Sendable, Codable {
    case stitch
    case bare
    case reload
}
