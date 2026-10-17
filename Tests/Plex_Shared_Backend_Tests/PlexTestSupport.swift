import Foundation
@testable import Plex_Shared_Backend
import Testing

func testIdentity() throws -> PlexClientIdentity {
    try PlexClientIdentity(identifier: "test-client", product: "Everything Client", version: "1", platform: "iOS")
}

func testConfiguration(base: String = "https://media.example/plex/") throws -> PlexServerConfiguration {
    try PlexServerConfiguration(baseURL: #require(URL(string: base)), token: "server-token", identity: testIdentity())
}

func decodeFixture<Value: Decodable>(_ type: Value.Type, _ json: String) throws -> Value {
    try JSONDecoder().decode(type, from: Data(json.utf8))
}

actor PlexStubTransport: PlexHTTPTransport {
    private(set) var requests: [URLRequest] = []
    private let body: Data
    private let status: Int
    private let nonHTTP: Bool

    init(_ json: String, status: Int = 200, nonHTTP: Bool = false) {
        body = Data(json.utf8)
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
