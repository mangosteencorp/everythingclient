import SwiftUI

#if DEBUG
public struct NoResultsDemoView: View {
    @State private var showNoResults = false
    @State private var useFancyDesign = true

    public init() {}

    public var body: some View {
        VStack {
            Button("Show No Results") {
                showNoResults = true
            }
            .padding()

            if showNoResults {
                if useFancyDesign {
                    if #available(iOS 17, *) {
                        FancyNoResultsView(
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
                            )
                        )
                    } else {
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
                } else {
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
}

#if DEBUG
#Preview {
    NoResultsDemoView()
}
#endif
#endif