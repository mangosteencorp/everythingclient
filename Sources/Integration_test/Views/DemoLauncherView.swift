import SwiftUI
#if DEBUG
@available(iOS 16, *)
public struct DemoLauncherView: View {
    @State private var selectedDemo: IntegrationTestLauncher.DemoTest?
    @State private var selectedPreview: PreviewCatalogEntry?

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("Demos") {
                    ForEach(IntegrationTestLauncher.getAvailableTests(), id: \.rawValue) { demo in
                        row(title: demo.displayName, subtitle: "Demo: \(demo.rawValue)") { selectedDemo = demo }
                    }
                }
                // Every module's Xcode previews, launchable on their own.
                ForEach(IntegrationTestLauncher.previewCatalogModules, id: \.self) { module in
                    Section(module) {
                        ForEach(IntegrationTestLauncher.previewCatalog(module: module)) { entry in
                            row(title: entry.name, subtitle: "Preview: \(entry.id)") { selectedPreview = entry }
                        }
                    }
                }
            }
            .navigationTitle("Integration Demos")
            .sheet(item: $selectedDemo) { demo in
                IntegrationTestLauncher.launch(demo)
            }
            .sheet(item: $selectedPreview) { entry in
                IntegrationTestLauncher.launch(entry)
            }
        }
        .accessibilityIdentifier("integration.preview.catalog")
    }

    private func row(title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
    }
}

@available(iOS 16, *)
extension IntegrationTestLauncher.DemoTest: Identifiable {
    public var id: String { rawValue }
}

@available(iOS 16, *)
#Preview {
    DemoLauncherView()
}
#endif
