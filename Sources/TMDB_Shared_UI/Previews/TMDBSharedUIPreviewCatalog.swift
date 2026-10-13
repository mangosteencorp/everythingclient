#if DEBUG
import SwiftUI

/// Every shared TMDB UI preview as a view of its own, so Xcode's canvas, the integration launcher
/// and the screenshot run all render the same thing. All of it is sample data.
public enum TMDBSharedUIPreviewCatalog: String, CaseIterable {
    case feedLoading
    case feedError
    case feedEmpty
    case feedLoadedRefreshing
    case feedPlaceholder
    case feedErrorOffline
    case feedErrorServer
    case noInternet
    case serverError
    case movieRows
    case popularityBadges
    case remoteImageNoArtwork

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .feedLoading:
            FeedStateView(phase: .loading, retryAction: {}, content: { EmptyView() })
        case .feedError:
            FeedStateView(phase: .error(message: "Invalid API key"), retryAction: {}, content: { EmptyView() })
        case .feedEmpty:
            FeedStateView(phase: .empty, retryAction: {}, content: { EmptyView() })
        case .feedLoadedRefreshing:
            FeedStateView(phase: .loaded, isRefreshing: true, retryAction: {}, content: {
                List(1...5, id: \.self) { Text("Movie \($0)") }
            })
        case .feedPlaceholder:
            FeedPlaceholderView(systemImage: "magnifyingglass", title: "Search for a movie")
        case .feedErrorOffline:
            FeedErrorContentView(
                message: "The Internet connection appears to be offline.",
                allowsCancelSearch: true,
                retryAction: {},
                cancelAction: {}
            )
        case .feedErrorServer:
            FeedErrorContentView(message: "Invalid API key", allowsCancelSearch: false, retryAction: {})
        default:
            component
        }
    }

    @MainActor @ViewBuilder
    private var component: some View {
        switch self {
        case .noInternet:
            NoInternetView(retryAction: {}, cancelAction: {})
        case .serverError:
            ServerErrorView(retryAction: {}, cancelAction: {})
        case .movieRows:
            List {
                MovieRow(movie: MovieRowEntity(
                    id: 550,
                    posterPath: nil,
                    title: "Fight Club",
                    voteAverage: 8.4,
                    releaseDate: Date(timeIntervalSince1970: 940_000_000),
                    overview: "A ticking-time-bomb insomniac and a slippery soap salesman channel primal male aggression into a shocking new form of therapy."
                ))
                MovieRow(movie: MovieRowEntity(
                    id: 807,
                    posterPath: nil,
                    title: "Se7en",
                    voteAverage: 5.1,
                    releaseDate: nil,
                    overview: "Two homicide detectives are on a desperate hunt for a serial killer."
                ), displayListImage: false)
            }
        case .popularityBadges:
            VStack {
                PopularityBadge(score: 80)
                PopularityBadge(score: 10)
                PopularityBadge(score: 30)
                PopularityBadge(score: 50)
            }
        default:
            RemoteTMDBImage(posterPath: nil, imageSize: .posterMedium)
                .frame(width: PosterSize.medium.width, height: PosterSize.medium.height)
        }
    }
}
#endif
