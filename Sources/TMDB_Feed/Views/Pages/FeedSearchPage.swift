import Shared_UI_Support
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

/// The search destination behind the shell's dedicated search button.
///
/// Covers all seven TMDB search endpoints through one scope picker, and renders every scope as
/// the same paginated list. Routing is the host's business: `routeBuilder` returns `nil` for
/// kinds this app has no page for (collections, companies, keywords), and those rows simply do
/// not push.
@available(iOS 17, *)
public struct FeedSearchPage<Route: Hashable>: View {
    @StateObject private var viewModel: SearchViewModel
    private let routeBuilder: (SearchResultItem) -> Route?

    public init(
        service: TMDBSearchServicing,
        routeBuilder: @escaping (SearchResultItem) -> Route?
    ) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(service: service))
        self.routeBuilder = routeBuilder
    }

    public var body: some View {
        results
            .navigationTitle(L10n.feedSearch)
            .searchable(text: $viewModel.query, prompt: L10n.searchPrompt)
            .searchScopes($viewModel.scope) {
                ForEach(SearchScope.allCases) { scope in
                    Text(scope.title).tag(scope)
                }
            }
            .accessibilityIdentifier("feed_search_page")
    }

    @ViewBuilder
    private var results: some View {
        FeedStateView(
            phase: phase,
            allowsCancel: true,
            retryAction: { viewModel.retry() },
            cancelAction: { viewModel.clear() },
            content: {
                List(viewModel.items) { item in
                    row(for: item)
                        .onAppear { viewModel.loadMoreIfNeeded(currentItem: item) }
                }
                .listStyle(.plain)
                .accessibilityIdentifier("search_results")
            }
        )
    }

    @ViewBuilder
    private func row(for item: SearchResultItem) -> some View {
        if let route = routeBuilder(item) {
            NavigationLink(value: route) {
                SearchResultRow(item: item)
            }
            .accessibilityIdentifier("search_result_\(item.id)")
        } else {
            SearchResultRow(item: item)
                .accessibilityIdentifier("search_result_\(item.id)")
        }
    }

    private var phase: FeedLoadPhase {
        if viewModel.isLoading, viewModel.items.isEmpty {
            return .loading
        }
        if let message = viewModel.errorMessage {
            return .error(message: message)
        }
        if !viewModel.hasSearched {
            return .placeholder(systemImage: "magnifyingglass", title: L10n.feedSearch)
        }
        return viewModel.items.isEmpty ? .empty : .loaded
    }
}

@available(iOS 16, *)
struct SearchResultRow: View {
    let item: SearchResultItem

    var body: some View {
        HStack(spacing: 12) {
            artwork
                .frame(width: PosterSize.thumbnail.width, height: PosterSize.thumbnail.height)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .lineLimit(2)
                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            if let voteAverage = item.voteAverage, voteAverage > 0 {
                PopularityBadge(score: Int(voteAverage * 10))
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var artwork: some View {
        if let imagePath = item.imagePath {
            RemoteTMDBImage(posterPath: imagePath, imageSize: .posterSmall)
        } else {
            // Keywords and most companies have no artwork at all.
            Image(systemName: item.kind.systemImage)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.secondarySystemBackground))
        }
    }
}
