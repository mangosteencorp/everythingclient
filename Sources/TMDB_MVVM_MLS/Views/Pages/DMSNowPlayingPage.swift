import SwiftUI
import Foundation
import Combine
import TMDB_Shared_UI
import TMDB_Shared_Backend
@available(iOS 16, macOS 10.15, *)
public struct DMSNowPlayingPage: View {
    @ObservedObject var viewModel: NowPlayingViewModel
    
    public init(apiKey: String){
        APIKeys.tmdbKey = apiKey
        viewModel = NowPlayingViewModel(apiService: TMDBAPIService(apiKey: APIKeys.tmdbKey))
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
                
                // Content below search bar
                Group {
                    if viewModel.isLoading {
                        ProgressView(L10n.playingLoading)
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                    } else {
                        List(viewModel.movies) { movie in
                            NavigationMovieRow(viewModel, movie: movie)
                        }
                    }
                }
            }
            .navigationTitle(L10n.playingTitle)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.fetchNowPlayingMovies()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

@available(iOS 16, macOS 10.15, *)
#Preview {
    // FIXME: preview with api key
    DMSNowPlayingPage(apiKey: "")
}


@available(iOS 16.0, *)
struct NavigationMovieRow: View {
    @ObservedObject var viewModel: NowPlayingViewModel
    let movie: Movie
    
    init(_ vm: NowPlayingViewModel, movie: Movie) {
        self.viewModel = vm
        self.movie = movie
    }
    
    var body: some View {
        NavigationLink(value: MovieDetailRoute(movie: MovieRouteModel(
            id: movie.id,
            title: movie.title,
            overview: movie.overview,
            posterPath: movie.poster_path,
            backdropPath: movie.backdrop_path,
            voteAverage: movie.vote_average,
            voteCount: movie.vote_count,
            releaseDate: movie.release_date,
            popularity: movie.popularity,
            originalTitle: movie.original_title
        )), label: {
            MovieRow(movie: movie.toMovieRowEntity())
        })
        .onAppear {
            debugPrint("onAppear \(movie.id):\(movie.title)")
            viewModel.fetchMoreContentIfNeeded(currentMovieId: movie.id)
        }
    }
}
