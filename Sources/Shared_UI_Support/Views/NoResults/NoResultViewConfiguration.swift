import SwiftUI

// Common interface for NoResultView parameters
public struct NoResultViewConfiguration {
    let primaryButtonAction: () -> Void
    let primaryButtonText: String
    let secondaryButtonAction: () -> Void
    let secondaryButtonText: String
    let headline: String
    let subheadline: String

    public init(
        primaryButtonAction: @escaping () -> Void = {},
        primaryButtonText: String = "Try Again",
        secondaryButtonAction: @escaping () -> Void = {},
        secondaryButtonText: String = "Clear Search",
        headline: String = "No Results Found",
        subheadline: String = "We couldn't find what you're looking for.\nTry adjusting your search terms."
    ) {
        self.primaryButtonAction = primaryButtonAction
        self.primaryButtonText = primaryButtonText
        self.secondaryButtonAction = secondaryButtonAction
        self.secondaryButtonText = secondaryButtonText
        self.headline = headline
        self.subheadline = subheadline
    }
}
