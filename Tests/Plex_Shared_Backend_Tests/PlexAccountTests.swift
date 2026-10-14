import Foundation
@testable import Plex_Shared_Backend
import Testing

struct PlexAccountTests {
    @Test func createsStrongPINWithStableClientIdentity() async throws {
        let transport = PlexStubTransport(#"{"id":123,"code":"pin-code","expiresIn":"1800","authToken":null}"#)
        let service = PlexAccountService(identity: try testIdentity(), transport: transport)
        let pin = try await service.createPIN()
        #expect(pin.id == "123")
        #expect(pin.expiresIn == 1800)
        #expect(pin.authToken == nil)
        let request = try #require(await transport.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://plex.tv/api/v2/pins?strong=true")
        #expect(request.value(forHTTPHeaderField: "X-Plex-Client-Identifier") == "test-client")
        #expect(request.value(forHTTPHeaderField: "X-Plex-Token") == nil)
    }

    @Test(arguments: ["null", "\"\"", "\"account-token\""])
    func pollsPendingAndClaimedPINs(token: String) async throws {
        let transport = PlexStubTransport("{\"id\":\"123\",\"code\":\"pin-code\",\"authToken\":\(token)}")
        let service = PlexAccountService(identity: try testIdentity(), transport: transport)
        let pin = try await service.pin(id: "123")
        #expect(pin.authToken == (token == "\"account-token\"" ? "account-token" : nil))
        let request = try #require(await transport.requests.first)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/api/v2/pins/123")
    }

    @Test(arguments: [404, 410, 401, 403, 429, 500])
    func handlesPINFailures(status: Int) async throws {
        let service = PlexAccountService(identity: try testIdentity(), transport: PlexStubTransport("{}", status: status))
        let expected: PlexAPIError = [404, 410].contains(status) ? .pinExpired : .httpStatus(status)
        await #expect(throws: expected) { try await service.pin(id: "123") }
    }

    @Test func encodesBrowserAuthorizationInFragment() throws {
        let identity = try PlexClientIdentity(identifier: "client&+id", product: "App + & Café", version: "1", platform: "iOS")
        let url = try PlexAccountService(identity: identity).authorizationURL(code: "code+&?#")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.host == "app.plex.tv")
        #expect(components.query == nil)
        let fragment = try #require(components.percentEncodedFragment)
        #expect(!fragment.contains("+"))
        let query = try #require(URLComponents(string: fragment)?.queryItems)
        #expect(query.first { $0.name == "clientID" }?.value == identity.identifier)
        #expect(query.first { $0.name == "code" }?.value == "code+&?#")
        #expect(query.first { $0.name == "context[device][product]" }?.value == identity.product)
    }

    @Test func discoversServersAndUsesEachServersToken() async throws {
        let transport = PlexStubTransport(#"""
        [
          {"clientIdentifier":"player","name":"Player","provides":"player"},
          {"clientIdentifier":"server","name":"Shared Server","provides":"server, player","owned":"0",
           "accessToken":"shared-server-token","connections":[
             {"uri":"https://media.example/proxy/","local":1,"relay":"false","IPv6":true}
           ]}
        ]
        """#)
        let service = PlexAccountService(identity: try testIdentity(), transport: transport)
        let servers = try await service.servers(accountToken: "account-token")
        #expect(servers.count == 1)
        let server = try #require(servers.first)
        #expect(server.id == "server")
        #expect(server.owned == false)
        #expect(server.connections.first?.local == true)
        #expect(server.connections.first?.ipv6 == true)
        let discovery = try #require(await transport.requests.first)
        #expect(discovery.value(forHTTPHeaderField: "X-Plex-Token") == "account-token")
        #expect(discovery.url?.absoluteString == "https://plex.tv/api/v2/resources?includeHttps=1&includeRelay=1&includeIPv6=1")
        let configuration = try server.configuration(connectionIndex: 0, identity: testIdentity())
        let request = try PlexEndpoint.libraries.makeRequest(configuration: configuration)
        #expect(request.url?.absoluteString == "https://media.example/proxy/library/sections")
        #expect(request.value(forHTTPHeaderField: "X-Plex-Token") == "shared-server-token")
        #expect(throws: PlexAPIError.invalidConfiguration) {
            try server.configuration(connectionIndex: -1, identity: testIdentity())
        }
    }

    @Test func missingServerTokenCannotUseAccountToken() throws {
        let server = try decodeFixture(PlexServerResource.self, #"{"clientIdentifier":"s","name":"Server","provides":"server","connections":[{"uri":"https://media.example"}]}"#)
        #expect(throws: PlexAPIError.invalidConfiguration) {
            try server.configuration(connectionIndex: 0, identity: testIdentity())
        }
    }

    @Test func invalidAccountCredentialFailsBeforeNetwork() async throws {
        let transport = PlexStubTransport("[]")
        let service = PlexAccountService(identity: try testIdentity(), transport: transport)
        await #expect(throws: PlexAPIError.invalidConfiguration) { try await service.servers(accountToken: "bad\r\ntoken") }
        #expect(await transport.requests.isEmpty)
    }
}
