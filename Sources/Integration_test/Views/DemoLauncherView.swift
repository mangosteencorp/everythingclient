import SwiftUI
#if DEBUG
@available(iOS 16, *)
public struct DemoLauncherView: View {
    @State private var selectedDemo: IntegrationTestLauncher.DemoTest?

    public init() {}

    public var body: some View {
        NavigationStack {
            List(IntegrationTestLauncher.getAvailableTests(), id: \.rawValue) { demo in
                Button(action: {
                    selectedDemo = demo
                }, label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(demo.displayName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Demo: \(demo.rawValue)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                })
            }
            .navigationTitle("Integration Demos")
            .sheet(item: $selectedDemo) { demo in
                IntegrationTestLauncher.launch(demo)
            }
        }
        .accessibilityIdentifier("integration.preview.catalog")
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
