import Combine
import Foundation
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 16, macOS 10.15, *)
public struct DMSNowPlayingPage<Route: Hashable>: View {
    @StateObject var viewModel: NowPlayingViewModel
    let detailRouteBuilder: (Movie) -> Route
    public init(
        apiKey: String,
        viewModel: NowPlayingViewModel? = nil,
        detailRouteBuilder: @escaping (Movie) -> Route
    ) {
        APIKeys.tmdbKey = apiKey
        _viewModel = StateObject(wrappedValue: viewModel ?? NowPlayingViewModel(
            apiService: TMDBAPIService(apiKey: APIKeys.tmdbKey)
        ))
        self.detailRouteBuilder = detailRouteBuilder
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Content
            Group {
                if viewModel.isLoading {
                    ProgressView(L10n.playingLoading)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                } else {
                    List(viewModel.movies) { movie in
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
    DMSNowPlayingPage(apiKey: "", detailRouteBuilder: { _ in 1 })
}

@available(iOS 16, macOS 10.15, *)
#Preview("now playing page within tab view") {
    TabView {
        DMSNowPlayingPage(apiKey: "",
                          detailRouteBuilder: { _ in 1 }).tag(0)
        Text("Second View").tag(1)
    }
}
// swiftlint:enable all
#endif
