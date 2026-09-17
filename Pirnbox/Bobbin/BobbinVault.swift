import Foundation

enum BobbinKeys {
    static let bobbin = "pnb.bobbin.v1"
    static let backup = "pnb.bobbin.v1.backup"
    static let demo = "pnb.demo.v1"
}

struct BobbinRecall: Sendable {
    var document: BobbinDocument
    var warning: BobbinWarning?
}

/// Role: Bobbin. Persistence seam. Views never touch UserDefaults or files.
protocol BobbinPinning: Sendable {
    func recall() async -> BobbinRecall
    func pin(_ document: BobbinDocument) async
    func commit(_ document: BobbinDocument) async throws
    func flush() async throws
    func wipe() async throws
    func demoPlanted() async -> Bool
    func markDemoPlanted() async
}

/// Role: Bobbin. In-memory source of truth stays on BobbinStore; this actor is the projection.
actor BobbinVault: BobbinPinning {
    private let directory: URL
    private let suiteName: String?
    private let fileManager: FileManager
    private let writeDelayNanoseconds: UInt64

    private var latest: BobbinDocument?
    private var writer: Task<Void, Never>?
    private(set) var lastWriteError: String?

    init(
        directory: URL,
        suiteName: String? = nil,
        fileManager: FileManager = .default,
        writeDelayNanoseconds: UInt64 = 250_000_000
    ) {
        self.directory = directory
        self.suiteName = suiteName
        self.fileManager = fileManager
        self.writeDelayNanoseconds = writeDelayNanoseconds
    }

    static func supportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Pirnbox", isDirectory: true)
    }

    func recall() async -> BobbinRecall {
        prepareFolder()
        if let document = open(defaults().data(forKey: BobbinKeys.bobbin)) {
            latest = document
            return BobbinRecall(document: document, warning: nil)
        }
        if let document = openFile(paperURL) {
            latest = document
            return BobbinRecall(document: document, warning: nil)
        }
        if let document = open(defaults().data(forKey: BobbinKeys.backup)) {
            latest = document
            return BobbinRecall(document: document, warning: .recoveredFromBackup)
        }
        if let document = openFile(backupURL) {
            latest = document
            return BobbinRecall(document: document, warning: .recoveredFromBackup)
        }
        let fresh = BobbinDocument.fresh()
        latest = fresh
        if hadPayload() {
            return BobbinRecall(document: fresh, warning: .startedFresh)
        }
        return BobbinRecall(document: fresh, warning: nil)
    }

    func pin(_ document: BobbinDocument) async {
        latest = document
        writer?.cancel()
        let delay = writeDelayNanoseconds
        writer = Task {
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await drain()
        }
    }

    func commit(_ document: BobbinDocument) async throws {
        writer?.cancel()
        writer = nil
        latest = document
        try persist(document)
    }

    func flush() async throws {
        writer?.cancel()
        writer = nil
        if let latest {
            try persist(latest)
        }
    }

    func wipe() async throws {
        writer?.cancel()
        writer = nil
        latest = BobbinDocument.fresh()
        lastWriteError = nil
        let defaults = defaults()
        defaults.removeObject(forKey: BobbinKeys.bobbin)
        defaults.removeObject(forKey: BobbinKeys.backup)
        defaults.removeObject(forKey: BobbinKeys.demo)
        removeIfPresent(paperURL)
        removeIfPresent(backupURL)
    }

    func demoPlanted() async -> Bool {
        defaults().object(forKey: BobbinKeys.demo) != nil
    }

    func markDemoPlanted() async {
        defaults().set(true, forKey: BobbinKeys.demo)
    }

    private func drain() async {
        writer = nil
        do {
            if let latest {
                try persist(latest)
            }
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func persist(_ document: BobbinDocument) throws {
        prepareFolder()
        let data = try BobbinCodec.encode(document)
        let defaults = defaults()
        if let previous = defaults.data(forKey: BobbinKeys.bobbin) {
            defaults.set(previous, forKey: BobbinKeys.backup)
        }
        if fileManager.fileExists(atPath: paperURL.path) {
            if fileManager.fileExists(atPath: backupURL.path) {
                do {
                    try fileManager.removeItem(at: backupURL)
                } catch {
                    // Replacing the previous backup is best-effort; the atomic write still proceeds.
                }
            }
            do {
                try fileManager.copyItem(at: paperURL, to: backupURL)
            } catch {
                // Copy of the previous good file is best-effort; the atomic write still proceeds.
            }
        }
        try data.write(to: paperURL, options: .atomic)
        defaults.set(data, forKey: BobbinKeys.bobbin)
        lastWriteError = nil
    }

    private func open(_ data: Data?) -> BobbinDocument? {
        guard let data else { return nil }
        return try? BobbinCodec.decode(data)
    }

    private func openFile(_ url: URL) -> BobbinDocument? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? BobbinCodec.decode(data)
    }

    private func hadPayload() -> Bool {
        defaults().data(forKey: BobbinKeys.bobbin) != nil
            || defaults().data(forKey: BobbinKeys.backup) != nil
            || fileManager.fileExists(atPath: paperURL.path)
            || fileManager.fileExists(atPath: backupURL.path)
    }

    private var paperURL: URL {
        directory.appendingPathComponent("bobbin.json")
    }

    private var backupURL: URL {
        directory.appendingPathComponent("bobbin.json.backup")
    }

    private func defaults() -> UserDefaults {
        if let suiteName {
            return UserDefaults(suiteName: suiteName) ?? .standard
        }
        return .standard
    }

    private func prepareFolder() {
        if fileManager.fileExists(atPath: directory.path) { return }
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func removeIfPresent(_ url: URL) {
        guard fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            // Wipe still clears UserDefaults even if a leftover file remains.
        }
    }
}

/// Role: Bobbin. In-process pin for tests. Same seam as the disk projection.
actor BobbinMemoryPin: BobbinPinning {
    private var document = BobbinDocument.fresh()
    private var demo = false

    func recall() async -> BobbinRecall {
        BobbinRecall(document: document, warning: nil)
    }

    func pin(_ document: BobbinDocument) async {
        self.document = document
    }

    func commit(_ document: BobbinDocument) async throws {
        self.document = document
    }

    func flush() async throws {}

    func wipe() async throws {
        document = BobbinDocument.fresh()
        demo = false
    }

    func demoPlanted() async -> Bool { demo }

    func markDemoPlanted() async { demo = true }
}
