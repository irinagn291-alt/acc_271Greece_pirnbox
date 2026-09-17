import Foundation
import Observation

/// Role: Bobbin. Owns the fold of Stitch, Bare, and ReloadMark. Views call stitch, reload, and retract.
@MainActor
@Observable
final class BobbinStore {
    private(set) var document: BobbinDocument
    private(set) var warning: BobbinWarning?
    private(set) var lastWriteError: String?

    private let pin: any BobbinPinning
    private let calendar: Calendar
    private var now: @Sendable () -> Date
    private var saveTask: Task<Void, Never>?

    init(
        pin: any BobbinPinning,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.pin = pin
        self.calendar = calendar
        self.now = now
        self.document = .fresh()
    }

    var bobbin: Bobbin { document.snapshot }

    func load() async {
        let recalled = await pin.recall()
        document = recalled.document
        warning = recalled.warning
        lastWriteError = nil
    }

    func stitch(at date: Date? = nil) {
        document.stitch(at: date ?? now(), calendar: calendar)
        persistSoon()
    }

    func reload(at date: Date? = nil) {
        _ = document.reload(at: date ?? now(), calendar: calendar)
        persistSoon()
    }

    func retract() {
        _ = document.retract()
        persistSoon()
    }

    func setCapacity(_ units: Int) throws {
        try document.setCapacity(units)
        persistSoon()
    }

    func markOnboardingComplete() {
        document.onboardingComplete = true
        persistSoon()
    }

    func reopenOnboarding() {
        document.onboardingComplete = false
        persistSoon()
    }

    func flush() async {
        saveTask?.cancel()
        saveTask = nil
        do {
            try await pin.commit(document)
            lastWriteError = nil
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    func resetAllData() async {
        saveTask?.cancel()
        saveTask = nil
        do {
            try await pin.wipe()
            lastWriteError = nil
        } catch {
            lastWriteError = String(describing: error)
        }
        document = .fresh()
        warning = nil
    }

    func seedDemoIfNeeded(now date: Date? = nil) async {
        #if targetEnvironment(simulator)
        if await pin.demoPlanted() { return }
        document = BobbinSeed.document(now: date ?? now(), calendar: calendar)
        warning = nil
        do {
            try await pin.commit(document)
            await pin.markDemoPlanted()
            lastWriteError = nil
        } catch {
            lastWriteError = String(describing: error)
        }
        #else
        _ = date
        #endif
    }

    private func persistSoon() {
        let snapshot = document
        saveTask?.cancel()
        saveTask = Task { [pin] in
            await pin.pin(snapshot)
        }
    }
}
