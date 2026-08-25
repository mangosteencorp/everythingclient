import SwiftUI
import third_party
#if canImport(SampleKit)
import SampleKit
#endif
@available(iOS 16.0, *)
public struct SettingsPageView: View {
    @State private var showSwiftfin = false
    @State private var showSamples = false
    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button("Launch Jellyfin by Swiftfin") {
                        showSwiftfin = true
                    }
                    .onLongPressGesture {
                        showSamples = true
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
        #if canImport(SampleKit)
        .fullScreenCover(isPresented: $showSamples) {
            SampleKitAllSamplesView()
        }
        #endif
    }
}

#if DEBUG
@available(iOS 16.0, *)
#Preview {
    SettingsPageView()
}
#endif
