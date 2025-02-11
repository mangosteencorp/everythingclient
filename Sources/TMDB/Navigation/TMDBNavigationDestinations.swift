import SwiftUI
import TMDB_MVVM_Detail
import Swinject
import TMDB_Shared_Backend
@available(iOS 16.0, *)
public struct TMDBNavigationDestinations: ViewModifier {
    let container: Container
    
    public func body(content: Content) -> some View {
        content
            .navigationDestination(for: TMDBRoute.self) { route in
                switch route {
                case .movieDetail(let movie):
                    MovieDetailPage(movieRoute: movie.toMovieDetailModel(), apiService: container.resolve(TMDBAPIService.self)!)
                case .tvShowDetail(let tvShowId):
                    Text("TV Show Detail \(tvShowId)") // Replace with actual TV show detail view
                }
            }
    }
}

// View extension for easier usage
@available(iOS 16.0, *)
public extension View {
    func withTMDBNavigationDestinations(container: Container) -> some View {
        modifier(TMDBNavigationDestinations(container: container))
    }
} 
