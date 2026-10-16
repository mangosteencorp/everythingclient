import Foundation
import Plex_Shared_Backend

/// Synthetic data only; sample mode never contacts a Plex account or media server.
/// Responses are looked up by `path?name=value` for each query item, then by `path`, then `*`.
nonisolated struct DemoFixtureTransport: PlexHTTPTransport {
    private static let responses: [String: Any] = Bundle.main.url(forResource: "DemoResponses", withExtension: "json")
        .flatMap { try? Data(contentsOf: $0) }
        .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try Task.checkCancellation()
        guard let url = request.url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])
        else { throw PlexAPIError.nonHTTPResponse }
        let keys = (components.queryItems ?? []).map { "\(url.path)?\($0.name)=\($0.value ?? "")" } + [url.path, "*"]
        guard let body = keys.lazy.compactMap({ Self.responses[$0] }).first else { throw PlexAPIError.httpStatus(404) }
        return (try JSONSerialization.data(withJSONObject: body), response)
    }
}
