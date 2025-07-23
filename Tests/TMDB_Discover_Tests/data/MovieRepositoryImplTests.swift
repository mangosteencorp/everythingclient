@testable import TMDB_Discover
import TMDB_Shared_Backend
import XCTest

class MovieRepositoryImplTests: XCTestCase {
    var repository: MovieRepositoryImpl!
    var mockAPIService: MockAPIService!

    override func setUp() {
        super.setUp()
        mockAPIService = MockAPIService()
        repository = MovieRepositoryImpl(apiService: mockAPIService)
    }

    func testFetchMoviesSuccess() async {
        // Setup mock API to return success...
        mockAPIService.resultToReturn = .success(MockData.movieListResultModel)
        let result = await repository.fetchNowPlayingMovies()
        if case let .success(movies) = result {
            XCTAssert(!movies.isEmpty, "Movies should not be empty on success")
            XCTAssertEqual(movies.count, 2, "Movies should not be empty on success")
        } else {
            XCTFail("Expected successful movie fetch")
        }
    }

    func testFetchMoviesFailure() async {
        // Setup mock API to return failure...
        mockAPIService.resultToReturn = .failure(MockError.noResponse)
        let result = await repository.fetchUpcomingMovies()
        if case let .success(movies) = result {
            XCTFail("Expected failure movie fetch but got \(movies)")
        } else {
            // Expected failure
            XCTAssertTrue(true)
        }
    }
}

class MockAPIService: APIServiceProtocol {
    func fetchTVShows(endpoint: TVShowFeedType) async -> Result<TMDB_Discover.TVShowListResultModel, Error> {
        return resultToReturn ?? .failure(MockError.noResponse)
    }

    func fetchGenres() async -> Result<GenreListModel, Error> {
        return .failure(MockError.noResponse)
    }

    func fetchPopularPeople() async -> Result<PersonListResultModel, Error> {
        return .failure(MockError.noResponse)
    }

    func fetchTrendingItems() async -> Result<TrendingAllResultModel, Error> {
        return .failure(MockError.noResponse)
    }

    var resultToReturn: Result<TMDB_Discover.TVShowListResultModel, Error>?
}
