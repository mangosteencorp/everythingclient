import CoreFeatures
import Shared_UI_Support
import SwiftUI

/// Everything a list-backed page can be showing, as one value: a view model publishes it and
/// `FeedStateView` renders it, so "loading with an error" or "content without content" cannot
/// be written down.
public enum FeedState<Item> {
    /// Nothing requested yet; the first load is about to start.
    case idle
    /// First load in flight, nothing on screen yet.
    case loading
    /// Nothing to show but this message.
    case error(message: String)
    /// The list; empty means the request succeeded with no results.
    case loaded([Item])
    /// The list, with a spinner over it while a replacement loads.
    case refreshing([Item])

    /// What is on screen; empty unless loaded or refreshing.
    public var items: [Item] {
        switch self {
        case let .loaded(items), let .refreshing(items): items
        case .idle, .loading, .error: []
        }
    }
}

/// The loading / error / empty / content ladder every feed and the search page repeat.
@available(iOS 16, *)
public struct FeedStateView<Item, Content: View>: View {
    let state: FeedState<Item>
    var allowsCancel: Bool = false
    /// Copy for the empty state; `nil` keeps the generic "No Results Found" wording.
    var emptyConfiguration: NoResultViewConfiguration?
    let retryAction: () -> Void
    var cancelAction: (() -> Void)?
    @ViewBuilder let content: ([Item]) -> Content

    @DesignStyle private var emptyStateDesign: FeedEmptyStateDesign

    public init(
        state: FeedState<Item>,
        allowsCancel: Bool = false,
        emptyConfiguration: NoResultViewConfiguration? = nil,
        retryAction: @escaping () -> Void,
        cancelAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping ([Item]) -> Content
    ) {
        self.state = state
        self.allowsCancel = allowsCancel
        self.emptyConfiguration = emptyConfiguration
        self.retryAction = retryAction
        self.cancelAction = cancelAction
        self.content = content
    }

    public var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView(L10n.playingLoading)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .error(message):
            FeedErrorContentView(
                message: message,
                allowsCancelSearch: allowsCancel,
                retryAction: retryAction,
                cancelAction: cancelAction
            )
        case let .loaded(items) where items.isEmpty:
            CommonNoResultView(
                configuration: emptyConfiguration ?? NoResultViewConfiguration(
                    primaryButtonAction: retryAction,
                    secondaryButtonAction: cancelAction ?? {}
                ),
                useFancyDesign: $emptyStateDesign.isFancy
            )
        // One branch for both, so starting or finishing a refresh keeps the list's identity
        // (and scroll position) instead of rebuilding it.
        case .loaded, .refreshing:
            content(state.items)
                .overlay {
                    if case .refreshing = state {
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

#if DEBUG
#Preview("Loading") {
    FeedStateView(state: FeedState<Int>.loading, retryAction: {}, content: { _ in EmptyView() })
}

#Preview("Error") {
    FeedStateView(state: FeedState<Int>.error(message: "Invalid API key"), retryAction: {}, content: { _ in EmptyView() })
}

#Preview("Empty") {
    FeedStateView(state: FeedState<Int>.loaded([]), retryAction: {}, content: { _ in EmptyView() })
        .designStyle(FeedEmptyStateDesign.fancy)
}

#Preview("Empty — plain") {
    FeedStateView(state: FeedState<Int>.loaded([]), retryAction: {}, content: { _ in EmptyView() })
        .designStyle(FeedEmptyStateDesign.plain)
}

#Preview("Refreshing") {
    FeedStateView(state: .refreshing(Array(1...5)), retryAction: {}, content: { items in
        List(items, id: \.self) { Text("Movie \($0)") }
    })
}

#Preview("Placeholder") {
    FeedPlaceholderView(systemImage: "magnifyingglass", title: "Search for a movie")
}
#endif
