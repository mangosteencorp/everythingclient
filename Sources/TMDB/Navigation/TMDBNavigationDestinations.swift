import SwiftUI
import TMDB_MVVM_Detail
@available(iOS 16.0, *)
public struct TMDBNavigationDestinations: ViewModifier {
    let apiKey: String
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func body(content: Content) -> some View {
        content
            .navigationDestination(for: TMDBRoute.self) { route in
                switch route {
                case .movieDetail(let movie):
                    MovieDetailPage(movieRoute: movie.toMovieDetailModel(), apiKey: apiKey)
                case .tvShowDetail(let tvShowId):
                    Text("TV Show Detail \(tvShowId)") // Replace with actual TV show detail view
                }
            }
    }
}

// View extension for easier usage
@available(iOS 16.0, *)
public extension View {
    func withTMDBNavigationDestinations(apiKey: String) -> some View {
        modifier(TMDBNavigationDestinations(apiKey: apiKey))
    }
} 
