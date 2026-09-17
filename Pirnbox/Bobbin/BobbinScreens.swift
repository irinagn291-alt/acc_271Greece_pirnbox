import SwiftUI

/// Role: Bobbin. Spec 3.6 screen names. Home, Calendar, Charts, History, Settings.
@MainActor
struct HomeView: View {
    @Bindable var watch: BobbinWatch
    var body: some View { BobbinHome(watch: watch) }
}

@MainActor
struct CalendarView: View {
    @Bindable var watch: BobbinWatch
    var body: some View { ReloadMarkCalendar(watch: watch) }
}

@MainActor
struct ChartsView: View {
    @Bindable var watch: BobbinWatch
    var body: some View { StitchCharts(watch: watch) }
}

@MainActor
struct HistoryView: View {
    @Bindable var watch: BobbinWatch
    var body: some View { StitchHistory(watch: watch) }
}

@MainActor
struct SettingsView: View {
    @Bindable var watch: BobbinWatch
    var body: some View { CapacitySettings(watch: watch) }
}
