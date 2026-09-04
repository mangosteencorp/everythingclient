import CoreFeatures
import Shared_UI_Support
import SwiftUI

/// What a feed has to show right now. Each call site maps its own view-model state onto this,
/// so the mapping stays visible while the rendering is shared.
enum FeedLoadPhase: Equatable {
    /// Nothing requested yet — search shows this before the first query.
    case placeholder(systemImage: String, title: String)
    case loading
    case error(message: String)
    case empty
    case loaded
}

/// The loading / error / empty / content ladder every feed repeats.
@available(iOS 16, *)
struct FeedStateView<Content: View>: View {
    let phase: FeedLoadPhase
    /// Spinner over already-visible content while the next page loads.
    var isRefreshing: Bool = false
    var allowsCancel: Bool = false
    let retryAction: () -> Void
    var cancelAction: (() -> Void)?
    @ViewBuilder let content: () -> Content

    @DesignStyle private var emptyStateDesign: FeedEmptyStateDesign

    var body: some View {
        switch phase {
        case let .placeholder(systemImage, title):
            FeedPlaceholderView(systemImage: systemImage, title: title)
        case .loading:
            ProgressView(L10n.playingLoading)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .error(message):
            FeedErrorContentView(
                message: message,
                allowsCancelSearch: allowsCancel,
                retryAction: retryAction,
                cancelAction: cancelAction
            )
        case .empty:
            CommonNoResultView(
                configuration: NoResultViewConfiguration(
                    primaryButtonAction: retryAction,
                    secondaryButtonAction: cancelAction ?? {}
                ),
                useFancyDesign: $emptyStateDesign.isFancy
            )
        case .loaded:
            content()
                .overlay {
                    if isRefreshing {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.05))
                    }
                }
        }
    }
}

struct FeedPlaceholderView: View {
    let systemImage: String
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("feed_search_placeholder")
    }
}

extension Binding where Value == FeedEmptyStateDesign {
    /// `CommonNoResultView` predates the design store and still speaks in booleans.
    var isFancy: Binding<Bool> {
        Binding<Bool>(
            get: { wrappedValue == .fancy },
            set: { wrappedValue = $0 ? .fancy : .plain }
        )
    }
}
