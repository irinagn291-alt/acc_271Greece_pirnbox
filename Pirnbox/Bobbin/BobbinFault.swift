import Foundation

/// Role: Bobbin. Recoverable faults. Decoding never crashes the process.
enum BobbinFault: Error, Equatable, Sendable {
    case invalidCapacity
    case unsupportedSchema(Int)
    case corrupt
}

/// Role: Bobbin. Load warnings. Fresh remaining equals default Capacity and is not written back.
enum BobbinWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedFresh
}
