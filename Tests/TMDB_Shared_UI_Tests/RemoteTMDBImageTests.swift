import Foundation
@testable import TMDB_Shared_UI
import UIKit
import XCTest

final class RemoteTMDBImageTests: XCTestCase {
    func testUIImageReadsCachedResponseWithoutNetwork() async throws {
        let url = URL(string: "https://image.test/cached.png")!
        let cache = URLCache(memoryCapacity: 1024 * 1024, diskCapacity: 0)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1), format: format).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        cache.storeCachedResponse(CachedURLResponse(
            response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!,
            data: try XCTUnwrap(image.pngData())
        ), for: URLRequest(url: url))
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        configuration.requestCachePolicy = .returnCacheDataDontLoad
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        let loaded = try await TMDBImageDownload.loadUIImage(from: url, session: session)
        XCTAssertEqual(loaded.size, image.size)
    }

    func testUIImageRejectsHTTPFailureAndNonImageData() async {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ImageFailureProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        for (path, code) in [("404", URLError.badServerResponse), ("invalid", URLError.cannotDecodeContentData)] {
            let url = URL(string: "https://image.test/\(path)")!
            do {
                _ = try await TMDBImageDownload.loadUIImage(from: url, session: session)
                XCTFail("Expected failure for \(path)")
            } catch {
                XCTAssertEqual((error as? URLError)?.code, code)
                XCTAssertEqual((error as NSError).userInfo[NSURLErrorFailingURLErrorKey] as? URL, url)
            }
        }
    }
}

private final class ImageFailureProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: request.url!.lastPathComponent == "404" ? 404 : 200,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("not an image".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
