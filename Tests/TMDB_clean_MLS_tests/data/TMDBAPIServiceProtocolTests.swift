@testable import TMDB_clean_MLS
import TMDB_Shared_Backend
import XCTest

class TMDBAPIServiceProtocolTests: XCTestCase {
    var apiService: TMDBAPIService!
    var mockConfig: URLSessionConfiguration!

    override func setUp() {
        super.setUp()
        mockConfig = URLSessionConfiguration.ephemeral
        mockConfig.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: mockConfig)
        apiService = TMDBAPIService(apiKey: "test_key", session: mockSession)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testFetchMoviesNowPlaying() async throws {
        // Given
        let mockResponse = MockData.movieListResultModel
        let mockData = try JSONEncoder().encode(mockResponse)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            XCTAssertTrue(request.url?.absoluteString.contains("airing_today") ?? false)
            return (response, mockData)
        }

        // When
        let result = await apiService.fetchMovies(endpoint: .nowPlaying)

        // Then
        switch result {
        case let .success(response):
            XCTAssertEqual(response.results.count, mockResponse.results.count)
            XCTAssertEqual(response.page, mockResponse.page)
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }

    func testFetchMoviesFailure() async {
        // Given
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.example.com")!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // When
        let result = await apiService.fetchMovies(endpoint: .nowPlaying)

        // Then
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case let .failure(error):
            XCTAssertTrue(error is TMDBAPIError)
        }
    }
}
