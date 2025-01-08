import SwiftUI
import Foundation
import Combine
import TMDB_Shared_UI
@available(iOS 16, macOS 10.15, *)
public struct DMSNowPlayingPage: View {
    @StateObject private var viewModel = NowPlayingViewModel()
    
    public init(apiKey: String){
        APIKeys.tmdbKey = apiKey
    }
    
    public var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    AnyView(ProgressView(L10n.playingLoading))
                } else if let errorMessage = viewModel.errorMessage {
                    AnyView(Text(errorMessage))
                } else {
                    AnyView(List(viewModel.movies) { movie in
                        VStack {
                            NavigationMovieRow(viewModel, movie: movie)
                        }
                        
                    })
                }
            }
            .navigationTitle(L10n.playingTitle)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.fetchNowPlayingMovies()
            }
        }.navigationViewStyle(StackNavigationViewStyle())
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
            popularity: movie.popularity, originalTitle: movie.original_title
        )), label: {
            MovieRow(movie: movie)
        })
        .onAppear {
            debugPrint("onAppear \(movie.id):\(movie.title)")
            viewModel.fetchMoreContentIfNeeded(currentMovieId: movie.id)
        }
    }
}
