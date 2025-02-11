import SwiftUI
import Foundation
import Combine
import TMDB_Shared_UI
import TMDB_Shared_Backend
@available(iOS 16, macOS 10.15, *)
public struct DMSNowPlayingPage<Route: Hashable>: View {
    @ObservedObject var viewModel: NowPlayingViewModel
    let detailRouteBuilder: (Movie) -> Route
    public init(apiKey: String,
                detailRouteBuilder: @escaping (Movie) -> Route) {
        APIKeys.tmdbKey = apiKey
        viewModel = NowPlayingViewModel(apiService: TMDBAPIService(apiKey: APIKeys.tmdbKey))
        self.detailRouteBuilder = detailRouteBuilder
        viewModel.fetchNowPlayingMovies()
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Sticky search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search movies...", text: $viewModel.searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemBackground))
                .accessibilityIdentifier("movielist1.searchbar")
                
                // Content below search bar
                Group {
                    if viewModel.isLoading {
                        ProgressView(L10n.playingLoading)
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                    } else {
                        List(viewModel.movies) { movie in
                            NavigationMovieRow(viewModel, movie: movie, routeBuilder: detailRouteBuilder)
                        }
                    }
                }
            }
            .accessibilityIdentifier("movielist1.group")
            .navigationTitle(L10n.playingTitle)
            .navigationBarTitleDisplayMode(.inline)
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
#if DEBUG
// swiftlint:disable all
@available(iOS 16, macOS 10.15, *)
#Preview {
    DMSNowPlayingPage(apiKey: "", detailRouteBuilder: {_ in return 1})
}
// swiftlint:enable all
#endif
