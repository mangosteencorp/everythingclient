import Shared_UI_Support
import SwiftUI

/// Shared error presentation for feed list and search failures.
public struct FeedErrorContentView: View {
    public let message: String
    public let allowsCancelSearch: Bool
    let retryAction: () -> Void
    let cancelAction: (() -> Void)?

    public init(
        message: String,
        allowsCancelSearch: Bool,
        retryAction: @escaping () -> Void,
        cancelAction: (() -> Void)? = nil
    ) {
        self.message = message
        self.allowsCancelSearch = allowsCancelSearch
        self.retryAction = retryAction
        self.cancelAction = cancelAction
    }

    public var body: some View {
        Group {
            if isLikelyNetworkError {
                NoInternetView(retryAction: retryAction, cancelAction: cancelButtonAction)
            } else {
                ServerErrorView(
                    message: message,
                    retryAction: retryAction,
                    cancelAction: cancelButtonAction
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .accessibilityIdentifier("feed.error.page")
    }

    private var cancelButtonAction: (() -> Void)? {
        allowsCancelSearch ? cancelAction : nil
    }

    public var isLikelyNetworkError: Bool {
        let lowered = message.lowercased()
        return lowered.contains("internet")
            || lowered.contains("offline")
            || lowered.contains("network")
            || lowered.contains("connection")
            || lowered.contains("nsurlerror")
            || lowered.contains("not connected")
    }
}
