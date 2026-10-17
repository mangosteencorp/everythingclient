import SwiftfinLauncher
import SwiftUI
#if canImport(SampleKit)
import SampleKit
#endif
@available(iOS 16.0, *)
public struct SettingsPageView: View {
    @State private var showSwiftfin = false
    @State private var showSamples = false
    @State private var connection: SwiftfinConnectionModel

    public init(sessionService: any SwiftfinSessionServicing = SwiftfinSessionService()) {
        _connection = State(initialValue: SwiftfinConnectionModel(service: sessionService))
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button(L10n.settingsLaunchSwiftfin) {
                        showSwiftfin = true
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in showSamples = true }
                    )
                    .accessibilityIdentifier("settings.launchSwiftfin.button")
                    SwiftfinConnectionStatusView(status: connection.status)
                } header: {
                    Text(L10n.settingsMediaServer)
                }
                .accessibilityIdentifier("settings.section.mediaServer")

                Section {
                    Text(L10n.settingsMoreComing)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(L10n.settingsAppearance)
                }
                .accessibilityIdentifier("settings.section.appearance")
            }
            .navigationTitle(L10n.settingsTitle)
            .accessibilityIdentifier("settings.page")
        }
        .fullScreenCover(isPresented: $showSwiftfin) {
            SwiftfinLaunchView()
        }
        .task(id: showSwiftfin) {
            guard !showSwiftfin else { return }
            await connection.refresh()
        }
        #if canImport(SampleKit)
        .fullScreenCover(isPresented: $showSamples) {
            NavigationStack {
                SampleKitAllSamplesView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                showSamples = false
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .accessibilityIdentifier("settings.samples.close.button")
                            .accessibilityLabel(L10n.settingsClose)
                        }
                    }
            }
        }
        #endif
    }
}

#if DEBUG
#Preview {
    TMDBPreviewCatalog.settings.view
}
#endif
