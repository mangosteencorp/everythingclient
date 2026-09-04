import CoreFeatures
import SwiftUI
// `third_party` wraps Swiftfin, which is UIKit-only; iOS only, see `Package.swift`.
#if os(iOS)
import third_party
#endif
#if canImport(SampleKit)
import SampleKit
#endif
@available(iOS 16.0, *)
public struct SettingsPageView: View {
    #if os(iOS)
    @State private var showSwiftfin = false
    #endif
    @State private var showSamples = false
    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                #if os(iOS)
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
                #endif

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
        #if os(iOS)
        .platformFullScreenCover(isPresented: $showSwiftfin) {
            SwiftfinLaunchView()
        }
        #endif
        #if canImport(SampleKit)
        .platformFullScreenCover(isPresented: $showSamples) {
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
