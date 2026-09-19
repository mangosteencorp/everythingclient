import CoreFeatures
import Shared_UI_Support
import SwiftUI

/// What a list-backed page has to show right now. Each call site maps its own view-model state
/// onto this, so the mapping stays visible while the rendering is shared.
public enum FeedLoadPhase: Equatable {
    /// Nothing requested yet — search shows this before the first query.
    case placeholder(systemImage: String, title: String)
    case loading
    case error(message: String)
    case empty
    case loaded
}

/// The loading / error / empty / content ladder every feed and the search page repeat.
@available(iOS 16, *)
public struct FeedStateView<Content: View>: View {
    let phase: FeedLoadPhase
    /// Spinner over already-visible content while the next page loads.
    var isRefreshing: Bool = false
    var allowsCancel: Bool = false
    let retryAction: () -> Void
    var cancelAction: (() -> Void)?
    @ViewBuilder let content: () -> Content

    @DesignStyle private var emptyStateDesign: FeedEmptyStateDesign

    public init(
        phase: FeedLoadPhase,
        isRefreshing: Bool = false,
        allowsCancel: Bool = false,
        retryAction: @escaping () -> Void,
        cancelAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.phase = phase
        self.isRefreshing = isRefreshing
        self.allowsCancel = allowsCancel
        self.retryAction = retryAction
        self.cancelAction = cancelAction
        self.content = content
    }

    public var body: some View {
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

public struct FeedPlaceholderView: View {
    let systemImage: String
    let title: String

    public init(systemImage: String, title: String) {
        self.systemImage = systemImage
        self.title = title
    }

    public var body: some View {
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

public extension Binding where Value == FeedEmptyStateDesign {
    /// `CommonNoResultView` predates the design store and still speaks in booleans.
    var isFancy: Binding<Bool> {
        Binding<Bool>(
            get: { wrappedValue == .fancy },
            set: { wrappedValue = $0 ? .fancy : .plain }
        )
    }
}
