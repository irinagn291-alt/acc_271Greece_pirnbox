import Foundation

/// Role: Bobbin. Codable envelope under pnb.bobbin.v1. Remaining is stored and is never Capacity.
struct BobbinDocument: Equatable, Sendable, Codable {
    var schemaVersion: Int
    var capacity: Int
    var remaining: Int
    var days: [BobbinDayFold]
    var writes: [BobbinWrite]
    var onboardingComplete: Bool

    static let currentSchema = 1

    init(
        schemaVersion: Int,
        capacity: Int,
        remaining: Int,
        days: [BobbinDayFold],
        writes: [BobbinWrite],
        onboardingComplete: Bool
    ) {
        self.schemaVersion = schemaVersion
        self.capacity = capacity
        self.remaining = remaining
        self.days = days
        self.writes = writes
        self.onboardingComplete = onboardingComplete
    }

    static func fresh(capacity units: Int = Capacity.origin.units) -> BobbinDocument {
        let size = max(1, units)
        return BobbinDocument(
            schemaVersion: currentSchema,
            capacity: size,
            remaining: size,
            days: [],
            writes: [],
            onboardingComplete: false
        )
    }

    var spool: Capacity { Capacity(units: capacity) }
    var thread: Remaining { Remaining(units: remaining) }

    var snapshot: Bobbin {
        Bobbin(
            capacity: spool,
            remaining: thread,
            onboardingComplete: onboardingComplete,
            canRetract: !writes.isEmpty
        )
    }

    var reloadDayKeys: [Int] {
        days.filter { !$0.reloads.isEmpty }.map(\.dayKey)
    }

    func stitchCount(on dayKey: Int) -> Int {
        days.first { $0.dayKey == dayKey }?.stitches.count ?? 0
    }

    func fold(on dayKey: Int) -> BobbinDayFold {
        days.first { $0.dayKey == dayKey }
            ?? BobbinDayFold(dayKey: dayKey, stitches: [], bares: [], reloads: [])
    }

    @discardableResult
    mutating func stitch(at date: Date, calendar: Calendar, id: UUID = UUID()) -> BobbinWriteKind {
        let dayKey = BobbinDay.key(from: date, calendar: calendar)
        var thread = Remaining(units: remaining)
        switch thread.spendOne() {
        case .bare:
            remaining = thread.units
            let mark = Bare(id: id, dayKey: dayKey, markedAt: date)
            mutateDay(dayKey) { $0.bares.append(mark) }
            writes.append(BobbinWrite(id: id, kind: .bare, dayKey: dayKey))
            return .bare
        case .stitch:
            remaining = thread.units
            let mark = Stitch(id: id, dayKey: dayKey, spentAt: date)
            mutateDay(dayKey) { $0.stitches.append(mark) }
            writes.append(BobbinWrite(id: id, kind: .stitch, dayKey: dayKey))
            return .stitch
        }
    }

    @discardableResult
    mutating func reload(at date: Date, calendar: Calendar, id: UUID = UUID()) -> Bool {
        guard remaining < capacity else { return false }
        let dayKey = BobbinDay.key(from: date, calendar: calendar)
        let mark = ReloadMark(
            id: id,
            dayKey: dayKey,
            remainingBefore: remaining,
            filedAt: date
        )
        remaining = capacity
        mutateDay(dayKey) { $0.reloads.append(mark) }
        writes.append(BobbinWrite(id: id, kind: .reload, dayKey: dayKey))
        return true
    }

    @discardableResult
    mutating func retract() -> BobbinWriteKind? {
        guard let last = writes.popLast() else { return nil }
        switch last.kind {
        case .stitch:
            var thread = Remaining(units: remaining)
            thread.restoreOne(limit: spool)
            remaining = thread.units
            removeWrite(id: last.id, kind: .stitch)
        case .bare:
            removeWrite(id: last.id, kind: .bare)
        case .reload:
            if let mark = reloadMark(id: last.id) {
                var thread = Remaining(units: remaining)
                thread.restore(before: mark.remainingBefore)
                remaining = thread.units
            }
            removeWrite(id: last.id, kind: .reload)
        }
        return last.kind
    }

    mutating func setCapacity(_ units: Int) throws {
        guard units >= 1 else { throw BobbinFault.invalidCapacity }
        capacity = units
        var thread = Remaining(units: remaining)
        thread.clamp(to: spool)
        remaining = thread.units
    }

    private mutating func mutateDay(_ dayKey: Int, _ body: (inout BobbinDayFold) -> Void) {
        if let index = days.firstIndex(where: { $0.dayKey == dayKey }) {
            body(&days[index])
            return
        }
        var fold = BobbinDayFold(dayKey: dayKey, stitches: [], bares: [], reloads: [])
        body(&fold)
        days.append(fold)
        days.sort { $0.dayKey < $1.dayKey }
    }

    private func reloadMark(id: UUID) -> ReloadMark? {
        for day in days {
            if let mark = day.reloads.first(where: { $0.id == id }) {
                return mark
            }
        }
        return nil
    }

    private mutating func removeWrite(id: UUID, kind: BobbinWriteKind) {
        for index in days.indices {
            switch kind {
            case .stitch:
                days[index].stitches.removeAll { $0.id == id }
            case .bare:
                days[index].bares.removeAll { $0.id == id }
            case .reload:
                days[index].reloads.removeAll { $0.id == id }
            }
        }
        days.removeAll { $0.isEmpty }
    }
}

enum BobbinCodec {
    static func encode(_ document: BobbinDocument) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.keyEncodingStrategy = .useDefaultKeys
        return try encoder.encode(document)
    }

    static func decode(_ data: Data) throws -> BobbinDocument {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw BobbinFault.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                var document = try decoder.decode(BobbinDocument.self, from: data)
                if document.remaining < 0 {
                    document.remaining = 0
                }
                return document
            } catch let fault as BobbinFault {
                throw fault
            } catch {
                throw BobbinFault.corrupt
            }
        default:
            throw BobbinFault.unsupportedSchema(probe.schemaVersion)
        }
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}

extension BobbinDocument {
    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case capacity
        case remaining
        case days
        case writes
        case onboardingComplete
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .schemaVersion)
        switch version {
        case 1:
            schemaVersion = version
            capacity = try container.decode(Int.self, forKey: .capacity)
            remaining = try container.decode(Int.self, forKey: .remaining)
            days = try container.decodeIfPresent([BobbinDayFold].self, forKey: .days) ?? []
            writes = try container.decodeIfPresent([BobbinWrite].self, forKey: .writes) ?? []
            onboardingComplete = try container.decodeIfPresent(Bool.self, forKey: .onboardingComplete) ?? false
        default:
            throw BobbinFault.unsupportedSchema(version)
        }
    }
}
