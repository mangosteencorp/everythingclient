import Combine
import Foundation
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 16, macOS 10.15, *)
public struct DMSNowPlayingPage<Route: Hashable>: View {
    @StateObject var viewModel: NowPlayingViewModel
    let detailRouteBuilder: (Movie) -> Route
    let analyticTracker: MovieFeedAnalyticsTrackerProtocol?
    public init(
        apiService: APIServiceProtocol,
        additionalParams: AdditionalMovieListParams? = nil,
        analyticTracker: MovieFeedAnalyticsTrackerProtocol? = nil,
        detailRouteBuilder: @escaping (Movie) -> Route
    ) {
        _viewModel = StateObject(wrappedValue: NowPlayingViewModel(
            apiService: apiService,
            additionalParams: additionalParams
        ))
        self.detailRouteBuilder = detailRouteBuilder
        self.analyticTracker = analyticTracker
    }

#if DEBUG
    init(
        viewModel: NowPlayingViewModel,
        detailRouteBuilder: @escaping (Movie) -> Route
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.detailRouteBuilder = detailRouteBuilder
        analyticTracker = nil
    }
#endif

    public var body: some View {
        VStack(spacing: 0) {
            Group {
                switch viewModel.state {
                case .initial:
                    EmptyView()
                case .loading:
                    ProgressView(L10n.playingLoading)
                case .error(let message):
                    Text(message)
                case .loaded(let movies), .searchResults(let movies):
                    List(movies) { movie in
                        NavigationMovieRow(viewModel, movie: movie, routeBuilder: detailRouteBuilder)
                    }.searchable(text: $viewModel.searchQuery)
                }
            }
        }
        .accessibilityIdentifier("movielist1.group")
        .navigationTitle(L10n.playingTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            viewModel.fetchNowPlayingMovies()
        }
    }
}

#if DEBUG
// swiftlint:disable all
@available(iOS 16, macOS 10.15, *)
#Preview {
    DMSNowPlayingPage(apiService: TMDBAPIService(apiKey: previewTMDBAPIKey),
                      detailRouteBuilder: { _ in 1 })
}

@available(iOS 16, macOS 10.15, *)
#Preview("now playing page within nested tab view") {
    TabView {
        TabView {
            NavigationStack {
                DMSNowPlayingPage(
                    apiService: TMDBAPIService(apiKey: previewTMDBAPIKey),
                    detailRouteBuilder: { _ in 1 }
                )
                .tag(0)
                .tabItem {
                    Label("First View", systemImage: "house")
                }
            }
            Text("Second View").tag(1)
                .tabItem {
                    Label("Second View", systemImage: "gear")
                }
        }
        //.tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .tag(0)
        .tabItem {
            Label("Outer First View", systemImage: "star")
        }
        Text("Outer Second View").tag(1)
            .tabItem {
                Label("Outer Second View", systemImage: "moon")
            }
    }
}
// swiftlint:enable all
#endif
