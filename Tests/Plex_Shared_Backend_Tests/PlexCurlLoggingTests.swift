import Foundation
@testable import Plex_Shared_Backend
import Synchronization
import Testing

struct PlexCurlLoggingTests {
    private func sampleRequest() throws -> URLRequest {
        var request = try #require(URL(string: "https://media.example/home/users/u/switch?pin=1234&keep=a%20b")).asRequest
        request.httpMethod = "POST"
        request.setValue("secret-token", forHTTPHeaderField: "X-Plex-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = Data(#"{"name":"it's"}"#.utf8)
        return request
    }

    @Test func curlCommandRedactsCredentialsByDefault() throws {
        let command = try sampleRequest().curlCommand()
        #expect(command.hasPrefix("curl \\\n  -X POST \\\n  'https://media.example/home/users/u/switch?pin=%5Bredacted%5D&keep=a%20b'"))
        #expect(command.contains("-H 'X-Plex-Token: [redacted]'") && command.contains("-H 'Accept: application/json'"))
        #expect(command.contains(#"--data-binary '{"name":"it'\''s"}'"#))
        #expect(!command.contains("secret-token") && !command.contains("1234"))
    }

    @Test func unredactedCommandCanBeReplayed() throws {
        let command = try sampleRequest().curlCommand(redactingCredentials: false)
        #expect(command.contains("X-Plex-Token: secret-token") && command.contains("pin=1234"))
    }

    @Test func loggingTransportLogsOnlyWhileEnabledAndForwardsUnchanged() async throws {
        let box = LineBox()
        let logger = PlexCurlLogger { line in box.lines.withLock { $0.append(line) } }
        let upstream = PlexStubTransport(#"{"MediaContainer":{}}"#)
        let api = try PlexAPIService(configuration: testConfiguration(), transport: PlexCurlLoggingTransport(upstream: upstream, logger: logger))
        _ = try await api.libraries()
        #expect(box.lines.withLock { $0.isEmpty })
        logger.isEnabled = true
        _ = try await api.libraries()
        logger.redactsCredentials = false
        _ = try await api.libraries()
        let logged = box.lines.withLock { $0 }
        #expect(logged.count == 2 && logged[0].contains("'https://media.example/plex/library/sections'"))
        #expect(logged[0].contains("[redacted]") && logged[1].contains("X-Plex-Token: server-token"))
        #expect(await upstream.requests.count == 3)
    }
}

private final class LineBox: Sendable {
    let lines = Mutex<[String]>([])
}

private extension URL {
    var asRequest: URLRequest { URLRequest(url: self) }
}
