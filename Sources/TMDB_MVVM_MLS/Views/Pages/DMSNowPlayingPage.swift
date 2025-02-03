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
                .accessibilityIdentifier("movielist1.searchbar")
                
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
            .accessibilityIdentifier("movielist1.group")
            .navigationTitle(L10n.playingTitle)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.fetchNowPlayingMovies()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
#if DEBUG
@available(iOS 16, macOS 10.15, *)
#Preview {
    DMSNowPlayingPage(apiKey: "")
}
#endif
