import AppCore
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

public struct MovieDetailPage: View {
    var movie: Movie
    @ObservedObject var movieDetailViewModel: MovieDetailViewModel
    @ObservedObject var creditsViewModel: MovieCastingViewModel
    let apiService: TMDBAPIService

    public init(movieRoute: Movie, apiService: TMDBAPIService) {
        // Convert MovieRouteModel to Movie
        movie = movieRoute
        self.apiService = apiService
        movieDetailViewModel = MovieDetailViewModel(apiService: self.apiService)
        creditsViewModel = MovieCastingViewModel(apiService: self.apiService)
    }

    public init(movieId: Int, apiService: TMDBAPIService) {
        movie = Movie.placeholder(id: movieId)
        self.apiService = apiService
        movieDetailViewModel = MovieDetailViewModel(apiService: self.apiService)
        creditsViewModel = MovieCastingViewModel(apiService: self.apiService)
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
                    if let kwList = getMovie().keywords?.keywords, !kwList.isEmpty {
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
        if case let .success(mov) = movieDetailViewModel.state {
            return mov
        }
        return movie
    }
}

#if DEBUG
let exampleMovieDetailPage: MovieDetailPage = {
    let apiService = TMDBAPIService(apiKey: "dummy-key")
    var page = MovieDetailPage(
        movieRoute: exampleMovieDetail,
        apiService: apiService
    )

    let movieDetailVM = MovieDetailViewModel(apiService: apiService)

    let creditVM = MovieCastingViewModel(apiService: apiService)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        movieDetailVM.state = .success(exampleMovieDetail)
        creditVM.state = .success(exampleMovieCredits)
    }
    page.creditsViewModel = creditVM
    page.movieDetailViewModel = movieDetailVM
    return page
}()

#Preview {
    return NavigationView {
        exampleMovieDetailPage
    }
}
#endif
