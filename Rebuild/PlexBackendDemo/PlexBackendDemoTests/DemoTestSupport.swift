import Foundation
import Plex_Shared_Backend
@testable import PlexBackendDemo

/// A session with throwaway storage and an in-memory credential store, so tests never touch the Keychain.
@MainActor
func makeSession(
    account: (any PlexAccountServing & PlexAccountProfileServing)? = nil,
    transport: any PlexHTTPTransport = PlexURLSessionTransport(),
    connector: (any PlexServerConnecting)? = nil,
    credentials: DemoMemoryCredentialStore = DemoMemoryCredentialStore(),
    storage: URL = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
) -> DemoSession {
    DemoSession(account: account, serverTransport: transport, connector: connector, credentials: credentials, storage: storage)
}

/// Routes by path, records requests, and can simulate a lost connection.
actor DemoRoutingTransport: PlexHTTPTransport {
    private(set) var requests: [URLRequest] = []
    private var routes: [String: String]
    private var failing = false

    init(_ routes: [String: String]) { self.routes = routes }

    func setFailing(_ value: Bool) { failing = value }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        if failing { throw URLError(.notConnectedToInternet) }
        let url = request.url ?? URL(filePath: "/")
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil) ?? HTTPURLResponse()
        return (Data((routes[url.path] ?? #"{"MediaContainer":{}}"#).utf8), response)
    }
}
