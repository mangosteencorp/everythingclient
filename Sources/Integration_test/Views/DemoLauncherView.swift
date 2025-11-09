import SwiftUI
@available(iOS 16, *)
struct DemoLauncherView: View {
    @State private var selectedDemo: IntegrationTestLauncher.DemoTest?

    var body: some View {
        NavigationView {
            List(IntegrationTestLauncher.getAvailableTests(), id: \.rawValue) { demo in
                Button(action: {
                    selectedDemo = demo
                }) {
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
                }
            }
            .navigationTitle("Integration Demos")
            .sheet(item: $selectedDemo) { demo in
                IntegrationTestLauncher.launch(demo)
            }
        }
    }
}

@available(iOS 16, *)
extension IntegrationTestLauncher.DemoTest: Identifiable {
    public var id: String { rawValue }
}

#if DEBUG
@available(iOS 16, *)
#Preview {
    DemoLauncherView()
}
#endif
