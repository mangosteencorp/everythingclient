import SwiftUI

#if DEBUG
struct NoResultViewPreview: View {
    @State private var showNoResults = false
    @State private var useFancyDesign = true

    var body: some View {
        VStack {
            Button("Show No Results") {
                showNoResults = true
            }
            .padding()

            if showNoResults {
                CommonNoResultView(
                    configuration: NoResultViewConfiguration(
                        primaryButtonAction: {
                            print("Primary button tapped")
                            showNoResults = false
                        },
                        primaryButtonText: "Retry Search",
                        secondaryButtonAction: {
                            print("Secondary button tapped")
                            showNoResults = false
                        },
                        secondaryButtonText: "Go Back",
                        headline: "No Results Found",
                        subheadline: "We couldn't find what you're looking for.\nTry adjusting your search terms."
                    ),
                    useFancyDesign: $useFancyDesign
                )
            }
        }
    }
}

#Preview("basics") {
    NoResultViewPreview()
}

#endif
