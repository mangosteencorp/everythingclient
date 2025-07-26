import Shared_UI_Support
import SwiftUI

struct DesignSwitcherDemoView: View {
    @State private var useFancyDesign = true

    var body: some View {
        VStack(spacing: 20) {
            Text("Design Switcher Demo")
                .font(.title)
                .padding()

            Text("Toggle between different design styles")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Toggle("Use Fancy Design", isOn: $useFancyDesign)
                .padding()

            VStack(spacing: 15) {
                Text("Sample Content")
                    .font(.headline)

                if useFancyDesign {
                    if #available(iOS 17, *) {
                        FancyNoResultsView()
                    } else {
                        CommonNoResultView(
                            configuration: NoResultViewConfiguration(
                                primaryButtonAction: { print("Primary tapped") },
                                primaryButtonText: "Try Again",
                                secondaryButtonAction: { print("Secondary tapped") },
                                secondaryButtonText: "Go Back",
                                headline: "No Results",
                                subheadline: "Try adjusting your search"
                            ),
                            useFancyDesign: $useFancyDesign
                        )
                    }
                } else {
                    CommonNoResultView(
                        configuration: NoResultViewConfiguration(
                            primaryButtonAction: { print("Primary tapped") },
                            primaryButtonText: "Try Again",
                            secondaryButtonAction: { print("Secondary tapped") },
                            secondaryButtonText: "Go Back",
                            headline: "No Results",
                            subheadline: "Try adjusting your search"
                        ),
                        useFancyDesign: $useFancyDesign
                    )
                }
            }
            .padding()

            Spacer()
        }
    }
}

#if DEBUG
@available(iOS 17, *)
#Preview {
    DesignSwitcherDemoView()
}
#endif