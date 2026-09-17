import SwiftUI

/// Role: Bobbin. Root chrome. Home never leaves. ReviewScreen is read after onboarding.
@MainActor
struct ContentView: View {
    @Bindable var watch: BobbinWatch

    var body: some View {
        NavigationStack {
            HomeView(watch: watch)
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    ContentView(watch: BobbinWatch.previewPopulated())
}
