import AppIntents

/// Role: Bobbin. App Intents open Home, Calendar, Charts, History, and Settings. No haptic.
struct OpenHomeIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Home" }
    static var description: IntentDescription { "Open the glass bobbin." }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        await BobbinWatch.shared.open(.home)
        return .result()
    }
}

struct OpenCalendarIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Calendar" }
    static var description: IntentDescription { "Open days that filed reload marks." }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        await BobbinWatch.shared.open(.sheet(.calendar))
        return .result()
    }
}

struct OpenChartsIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Charts" }
    static var description: IntentDescription { "Open stitches versus capacity." }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        await BobbinWatch.shared.open(.sheet(.charts))
        return .result()
    }
}

struct OpenHistoryIntent: AppIntent {
    static var title: LocalizedStringResource { "Open History" }
    static var description: IntentDescription { "Open stitch order, bare marks, and reloads." }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        await BobbinWatch.shared.open(.sheet(.history))
        return .result()
    }
}

struct OpenSettingsIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Settings" }
    static var description: IntentDescription { "Open capacity, contact, and reset." }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        await BobbinWatch.shared.open(.sheet(.settings))
        return .result()
    }
}

struct PirnboxShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenHomeIntent(),
            phrases: [
                "Open Home in \(.applicationName)",
                "Open the bobbin in \(.applicationName)",
            ],
            shortTitle: "Home",
            systemImageName: "circle"
        )
        AppShortcut(
            intent: OpenCalendarIntent(),
            phrases: [
                "Open Calendar in \(.applicationName)",
            ],
            shortTitle: "Calendar",
            systemImageName: "calendar"
        )
        AppShortcut(
            intent: OpenChartsIntent(),
            phrases: [
                "Open Charts in \(.applicationName)",
            ],
            shortTitle: "Charts",
            systemImageName: "chart.bar"
        )
        AppShortcut(
            intent: OpenHistoryIntent(),
            phrases: [
                "Open History in \(.applicationName)",
            ],
            shortTitle: "History",
            systemImageName: "list.bullet"
        )
        AppShortcut(
            intent: OpenSettingsIntent(),
            phrases: [
                "Open Settings in \(.applicationName)",
            ],
            shortTitle: "Settings",
            systemImageName: "gearshape"
        )
    }
}
