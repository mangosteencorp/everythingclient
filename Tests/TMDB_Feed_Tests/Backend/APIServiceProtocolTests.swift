import SwiftUI
@testable import TMDB_Feed
import TMDB_Shared_Backend
import TMDB_Shared_UI
import XCTest

class APIServiceProtocolTests: XCTestCase {
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

    func testFetchNowPlayingMoviesSuccess() async throws {
        // Given
        let mockData = try Data(contentsOf: Bundle.module.url(forResource: "nowplaying", withExtension: "json")!)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            XCTAssertTrue(request.url?.absoluteString.contains("now_playing") ?? false)
            return (response, mockData)
        }

        // When
        let result = await apiService.fetchNowPlayingMovies(page: 1)

        // Then
        switch result {
        case let .success(response):
            XCTAssertEqual(response.page, 2)
            XCTAssertEqual(response.results.count, 20)
            XCTAssertEqual(response.results.first?.title, "Brave the Dark")
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }

    func testFetchNowPlayingMoviesFailure() async {
        // Given
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.themoviedb.org")!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // When
        let result = await apiService.fetchNowPlayingMovies(page: 1)

        // Then
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case let .failure(error):
            XCTAssertNotNil(error)
        }
    }

    func testSearchMoviesSuccess() async throws {
        // Given
        let mockData = try Data(contentsOf: Bundle.module.url(forResource: "nowplaying", withExtension: "json")!)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            XCTAssertTrue(request.url?.absoluteString.contains("search/movie") ?? false)
            return (response, mockData)
        }

        // When
        let result = await apiService.searchMovies(query: "test", page: 1)

        // Then
        switch result {
        case let .success(response):
            XCTAssertEqual(response.page, 2)
            XCTAssertEqual(response.results.count, 20)
            XCTAssertEqual(response.results.first?.title, "Brave the Dark")
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }

    func testSearchMoviesFailure() async {
        // Given
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.themoviedb.org")!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // When
        let result = await apiService.searchMovies(query: "test", page: 1)

        // Then
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case let .failure(error):
            XCTAssertNotNil(error)
        }
    }
}

// Mock URLProtocol for testing network requests
class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("Received unexpected request with no handler set")
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
