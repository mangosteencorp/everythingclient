import Foundation
@testable import RSS_Shared_Backend
import Testing

/// A trimmed copy of the real IGN Movie Reviews feed: six episodes, including the "Superman" traps and two
/// "Silent Night" reviews, plus one item without an enclosure.
func ignFixtureData() throws -> Data {
    try Data(contentsOf: #require(Bundle.module.url(forResource: "ign-movie-review", withExtension: "xml")))
}

func ignFixtureFeed() throws -> RSSFeed {
    try RSSParser().parse(ignFixtureData())
}

/// A minimal RSS 2.0 document with one item made of `item`'s XML.
func parseFeed(channel: String = "", item: String) throws -> RSSFeed {
    try RSSParser().parse(Data("""
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
      <channel><title>Show</title>\(channel)<item>\(item)</item></channel>
    </rss>
    """.utf8))
}

actor RSSStubTransport: RSSHTTPTransport {
    private(set) var requests: [URLRequest] = []
    private let body: Data
    private let status: Int
    private let nonHTTP: Bool

    init(_ body: Data, status: Int = 200, nonHTTP: Bool = false) {
        self.body = body
        self.status = status
        self.nonHTTP = nonHTTP
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        let url = try #require(request.url)
        let response = nonHTTP
            ? URLResponse(url: url, mimeType: nil, expectedContentLength: body.count, textEncodingName: nil)
            : try #require(HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil))
        return (body, response)
    }
}
