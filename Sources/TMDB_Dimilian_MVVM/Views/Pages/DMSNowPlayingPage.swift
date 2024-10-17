// DMS: Dimilian Simplified View

import SwiftUI
import Foundation
import Combine

@available(iOS 15, macOS 10.15, *)
public struct DMSNowPlayingPage: View {
    @StateObject private var viewModel = NowPlayingViewModel()
    public init(apiKey: String){
        APIKeys.tmdbKey = apiKey
    }
    public var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView(L10n.playingLoading)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                } else {
                    List(viewModel.movies) { movie in
                        MovieRow(movie: movie)
                    }
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

@available(iOS 15, macOS 10.15, *)
#Preview {
    DMSNowPlayingPage(apiKey: "")
}

