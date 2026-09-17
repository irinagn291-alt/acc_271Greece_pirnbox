import Foundation
import Observation
import SwiftUI

/// Role: Bobbin. Presentation director. Views call stitch, reload, retract. They never touch UserDefaults.
@MainActor
@Observable
final class BobbinWatch {
    static let shared: BobbinWatch = .live()

    let store: BobbinStore
    private(set) var document: BobbinDocument
    private(set) var warning: BobbinWarning?
    private(set) var persistFailed = false
    private(set) var capacityFault: String?
    private(set) var busy = false
    private(set) var pulse = 0
    private(set) var showSuccess = false
    private(set) var dayKey: Int
    var sheet: BobbinSheet?
    var showOnboarding = false

    @ObservationIgnored private let handlesLaunch: Bool
    @ObservationIgnored private var reviewConsumed = false
    @ObservationIgnored private var pendingRoute: BobbinRoute?
    @ObservationIgnored private var spinnerTask: Task<Void, Never>?
    private(set) var showSpinner = false

    var bobbin: Bobbin { document.snapshot }
    var remaining: Int { document.remaining }
    var capacity: Int { document.capacity }
    var canRetract: Bool { bobbin.canRetract }
    var reloadEnabled: Bool { bobbin.reloadEnabled }
    var isSpent: Bool { bobbin.isSpent }
    var stitchEnabled: Bool { bobbin.stitchEnabled }
    var todayStitchCount: Int { document.stitchCount(on: dayKey) }

    init(store: BobbinStore, handlesLaunch: Bool = true) {
        self.store = store
        self.handlesLaunch = handlesLaunch
        self.document = store.document
        self.warning = store.warning
        self.showOnboarding = !store.bobbin.onboardingComplete
        self.dayKey = BobbinDay.key(from: Date(), calendar: .current)
    }

    static func live() -> BobbinWatch {
        do {
            let directory = try BobbinVault.supportDirectory()
            let pin = BobbinVault(directory: directory)
            return BobbinWatch(store: BobbinStore(pin: pin))
        } catch {
            let watch = BobbinWatch(store: BobbinStore(pin: BobbinMemoryPin()), handlesLaunch: false)
            watch.persistFailed = true
            return watch
        }
    }

    static func previewPopulated() -> BobbinWatch {
        let watch = BobbinWatch(store: BobbinStore(pin: BobbinMemoryPin()), handlesLaunch: false)
        let today = Date()
        for _ in 0 ..< 5 {
            watch.store.stitch(at: today)
        }
        watch.sync()
        return watch
    }

    func bootstrap() async {
        guard handlesLaunch else { return }
        persistFailed = false
        await store.load()
        await store.seedDemoIfNeeded()
        sync()
        showOnboarding = !store.bobbin.onboardingComplete
        if !showOnboarding {
            applyReviewOnce()
            applyPending()
        }
    }

    func finishOnboarding() async {
        store.markOnboardingComplete()
        await store.flush()
        sync()
        showOnboarding = false
        applyReviewOnce()
        applyPending()
    }

    func skipOnboarding() async {
        await finishOnboarding()
    }

    func handle(phase: ScenePhase) async {
        if phase == .active {
            tickDay()
        }
        if phase == .inactive || phase == .background {
            await store.flush()
            sync()
        }
    }

    func tickDay() {
        dayKey = BobbinDay.key(from: Date(), calendar: .current)
    }

    func stitch() {
        guard !busy else { return }
        beginBusy()
        store.stitch()
        finishCommit()
    }

    func reload() {
        guard !busy else { return }
        guard reloadEnabled else { return }
        beginBusy()
        store.reload()
        finishCommit()
    }

    func retract() {
        guard !busy, canRetract else { return }
        beginBusy()
        store.retract()
        finishCommit()
    }

    func setCapacity(_ units: Int) {
        do {
            try store.setCapacity(units)
            capacityFault = nil
            persistFailed = false
            sync()
        } catch {
            capacityFault = "Capacity must be at least one unit."
        }
    }

    func reopenOnboarding() {
        sheet = nil
        store.reopenOnboarding()
        sync()
        showOnboarding = true
    }

    func resetAllData() async {
        await store.resetAllData()
        persistFailed = store.lastWriteError != nil
        capacityFault = nil
        sheet = nil
        showOnboarding = true
        reviewConsumed = true
        sync()
    }

    func retryLoad() async {
        persistFailed = false
        await store.load()
        sync()
        persistFailed = store.lastWriteError != nil
    }

    func retryFlush() async {
        await store.flush()
        persistFailed = store.lastWriteError != nil
        sync()
    }

    func open(_ route: BobbinRoute) {
        guard !showOnboarding else {
            pendingRoute = route
            return
        }
        apply(route)
    }

    func open(url: URL) {
        guard let route = BobbinRoute.parse(url) else { return }
        open(route)
    }

    func openSheet(_ sheet: BobbinSheet) {
        open(.sheet(sheet))
    }

    func dismissSheet() {
        sheet = nil
    }

    func applyReviewOnce(arguments: [String] = ProcessInfo.processInfo.arguments) {
        guard !reviewConsumed else { return }
        guard store.bobbin.onboardingComplete, !showOnboarding else { return }
        reviewConsumed = true
        if let route = BobbinRoute.parseReview(arguments: arguments) {
            apply(route)
        }
    }

    private func apply(_ route: BobbinRoute) {
        switch route {
        case .home:
            sheet = nil
        case .sheet(let sheet):
            self.sheet = sheet
        }
    }

    private func applyPending() {
        guard !showOnboarding else { return }
        if let pendingRoute {
            self.pendingRoute = nil
            apply(pendingRoute)
        }
    }

    private func beginBusy() {
        busy = true
        spinnerTask?.cancel()
        spinnerTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard let self, !Task.isCancelled, self.busy else { return }
            self.showSpinner = true
        }
    }

    private func finishCommit() {
        persistFailed = store.lastWriteError != nil
        sync()
        pulse += 1
        showSuccess = true
        busy = false
        showSpinner = false
        spinnerTask?.cancel()
        spinnerTask = nil
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(700))
            self?.showSuccess = false
        }
    }

    private func sync() {
        document = store.document
        warning = store.warning
        if let last = store.lastWriteError, !last.isEmpty {
            persistFailed = true
        }
    }
}
