import SwiftUI
import TMDB_Person

@available(iOS 16.0, *)
public struct SettingsPageView: View {
    @State private var showSwiftfin = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button("Launch Jellyfin by Swiftfin") {
                        showSwiftfin = true
                    }
                    .accessibilityIdentifier("settings.launchSwiftfin.button")
                } header: {
                    Text("Media Server")
                }
                .accessibilityIdentifier("settings.section.mediaServer")

                Section {
                    Text("More settings coming soon.")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Appearance")
                }
                .accessibilityIdentifier("settings.section.appearance")
            }
            .navigationTitle("Settings")
            .accessibilityIdentifier("settings.page")
        }
        .fullScreenCover(isPresented: $showSwiftfin) {
            SwiftfinLaunchView()
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
#Preview {
    SettingsPageView()
}
#endif
