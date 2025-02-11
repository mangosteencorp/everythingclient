import SwiftUI
import TMDB_Shared_UI
import TMDB_Shared_Backend
import AppCore

public struct MovieDetailPage: View {
    var movie: Movie
    @ObservedObject var movieDetailViewModel: MovieDetailViewModel
    @ObservedObject var creditsViewModel: MovieCastingViewModel
    let apiService: TMDBAPIService
    
    public init(movieRoute: Movie, apiService: TMDBAPIService) {
        // Convert MovieRouteModel to Movie
        self.movie = movieRoute
        self.apiService = apiService
        self.movieDetailViewModel = MovieDetailViewModel(apiService: self.apiService)
        self.creditsViewModel = MovieCastingViewModel(apiService: self.apiService)
    }
    
    public init(movieId: Int, apiService: TMDBAPIService) {
        self.movie = Movie.placeholder(id: movieId)
        self.apiService = apiService
        self.movieDetailViewModel = MovieDetailViewModel(apiService: self.apiService)
        self.creditsViewModel = MovieCastingViewModel(apiService: self.apiService)
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            List {
                Section {
                    MovieCoverRow(movie: getMovie())
                        .frame(height: 250)
                }
                Section {
                    MovieOverview(movie: getMovie())
                }
                Section {
                    if let kwList = getMovie().keywords?.keywords, kwList.count > 0 {
                        MovieKeywords(
                            keywords: kwList,
                            specialKeywordIds: TabManager.shared.specialKeywordIdList(),
                            onSpecialKeywordLongPress: { kwId in
                                TabManager.shared.enableSpecialTab(specialKeywordId: kwId)
                            }
                        )
                        
                    }
                    MovieCreditSection(movieId: movie.id, creditsViewModel: creditsViewModel)
                }
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle(Text(getMovie().userTitle), displayMode: .large)
        }.onFirstAppear {
            movieDetailViewModel.fetchMovieDetail(movieId: movie.id)
        }
    }
    
    func getMovie() -> Movie {
        if case .success(let mv) = movieDetailViewModel.state {
            return mv
        }
        return movie
    }
}
#if DEBUG
let exampleMovieDetailPage: MovieDetailPage = {
    let apiService = TMDBAPIService(apiKey: "dummy-key")
    var p = MovieDetailPage(
        movieRoute: exampleMovieDetail,
        apiService: apiService
    )
    
    let movieDetailVM = MovieDetailViewModel(apiService: apiService)
    
    let creditVM = MovieCastingViewModel(apiService: apiService)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        movieDetailVM.state = .success(exampleMovieDetail)
        creditVM.state = .success(exampleMovieCredits)
    }
    p.creditsViewModel = creditVM
    p.movieDetailViewModel = movieDetailVM
    return p
}()

#Preview {
    return NavigationView {
        exampleMovieDetailPage
    }
}
#endif
