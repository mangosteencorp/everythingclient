import SwiftUI

struct ContentView: View {
    @State private var session = DemoSession()

    var body: some View {
        RootTabs()
            .environment(session)
            .task {
                if ProcessInfo.processInfo.arguments.contains("--fixtures") { session.loadSamples() } else { await session.restore() }
            }
    }
}

/// Home, Library, Search, Downloads and Account, with an offline/sample banner and a shared error alert.
struct RootTabs: View {
    @Environment(DemoSession.self) private var session
    @State private var selectedTab = Tabs.home

    enum Tabs: Hashable { case home, library, search, downloads, account }

    var body: some View {
        @Bindable var session = session
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: Tabs.home) { HomeView() }
            Tab("Library", systemImage: "rectangle.stack", value: Tabs.library) { LibraryView() }
            Tab("Downloads", systemImage: "arrow.down.circle", value: Tabs.downloads) { DownloadsView() }
            Tab("Account", systemImage: "person.crop.circle", value: Tabs.account) { AccountView() }
            Tab(value: Tabs.search, role: .search) { SearchView() }
        }
        .frame(minWidth: 360, minHeight: 540)
        .alert("Something went wrong", isPresented: Binding(get: { session.error != nil }, set: { if !$0 { session.error = nil } })) {
            Button("OK", role: .cancel) { session.error = nil }
        } message: { Text(session.error ?? "") }
        .onChange(of: session.api == nil) { _, disconnected in
            if disconnected, !session.transfers.offlineItems.isEmpty, !session.isConnecting { selectedTab = .downloads }
        }
    }
}

/// Explains why content may be stale: offline mode or synthetic sample data.
struct StatusBanner: View {
    @Environment(DemoSession.self) private var session

    var body: some View {
        if session.isOffline {
            HStack {
                Label("Offline — showing saved content", systemImage: "wifi.slash")
                Spacer()
                Button("Go online") { Task { await session.setOffline(false) } }.buttonStyle(.bordered)
            }
            .font(.caption).padding(8).background(.orange.opacity(0.15))
            .accessibilityIdentifier("plex.offlineBanner")
        } else if session.isSample {
            Label("Sample mode — synthetic data", systemImage: "testtube.2")
                .font(.caption).padding(6).frame(maxWidth: .infinity).background(.yellow.opacity(0.15))
        }
    }
}

extension View {
    /// Pins the offline/sample banner below a tab's navigation bar.
    func statusBanner() -> some View { safeAreaInset(edge: .top, spacing: 0) { StatusBanner() } }
}

#Preview { RootTabs().environment(DemoSession.preview()) }
#Preview("Banner") { StatusBanner().environment(DemoSession.preview()) }
