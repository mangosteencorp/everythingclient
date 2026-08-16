import Shared_UI_Support
import SwiftUI
import TMDB_Shared_UI

/// Shared error presentation for feed list and search failures.
struct FeedErrorContentView: View {
    let message: String
    let allowsCancelSearch: Bool
    let retryAction: () -> Void
    let cancelAction: (() -> Void)?

    var body: some View {
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

    var isLikelyNetworkError: Bool {
        let lowered = message.lowercased()
        return lowered.contains("internet")
            || lowered.contains("offline")
            || lowered.contains("network")
            || lowered.contains("connection")
            || lowered.contains("nsurlerror")
            || lowered.contains("not connected")
    }
}
