import Foundation
@testable import Plex_Shared_Backend
import Testing

struct PlexExtendedAPITests {
    @Test func rawMutationsAcceptEmptySuccessfulResponses() async throws {
        let transport = PlexStubTransport("", status: 204)
        let service = PlexAPIService(configuration: try testConfiguration(), transport: transport)
        let body = Data(#"{"title":"New title"}"#.utf8)
        let result = try await service.execute(
            path: "/library/metadata/42/prefs",
            method: .put,
            query: [URLQueryItem(name: "language", value: "en + fr")],
            body: body
        )
        #expect(result.statusCode == 204 && result.data.isEmpty)
        let request = try #require(await transport.requests.first)
        #expect(request.httpMethod == "PUT" && request.httpBody == body)
        #expect(request.value(forHTTPHeaderField: "X-Plex-Token") == "server-token")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.url?.path == "/plex/library/metadata/42/prefs")
        #expect(URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)?.queryItems?.first?
            .value == "en + fr")
    }

    @Test(arguments: [
        "https://evil.example/file",
        "//evil.example/file",
        "/../file",
        "/%252e%252e/file",
        "/path?X-Plex-Token=other",
    ])
    func arbitraryRequestsRetainServerScope(path: String) async throws {
        let transport = PlexStubTransport("{}")
        let service = PlexAPIService(configuration: try testConfiguration(), transport: transport)
        await #expect(throws: PlexAPIError.invalidPath) { try await service.execute(path: path) }
        #expect(await transport.requests.isEmpty)
    }

    @Test func extraQueryCannotInjectCredential() async throws {
        let service = PlexAPIService(configuration: try testConfiguration())
        #expect(throws: PlexAPIError.invalidPath) {
            try service.makeRequest(path: "/identity", query: [URLQueryItem(name: "x-PLEX-token", value: "other")])
        }
        #expect(throws: PlexAPIError.invalidConfiguration) {
            try service.makeRequest(path: "/identity", contentType: "application/json\r\nOther: injected")
        }
    }

    @Test func newBrowseEndpointsUsePagingAndEncodeSearch() async throws {
        let transport = PlexStubTransport(#"{"MediaContainer":{"Metadata":[]}}"#)
        let service = PlexAPIService(configuration: try testConfiguration(), transport: transport)
        _ = try await service.search(query: "A & B + C", page: PlexPagination(start: 50, size: 25))
        _ = try await service.recentlyAdded(page: PlexPagination(size: 10))
        _ = try await service.extras(ratingKey: "movie + 42")
        let requests = await transport.requests
        let firstURL = try #require(requests.first?.url)
        let query = try #require(URLComponents(url: firstURL, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(query.first(where: { $0.name == "query" })?.value == "A & B + C")
        #expect(firstURL.absoluteString.contains("%2B"))
        #expect(query.first(where: { $0.name == "X-Plex-Container-Start" })?.value == "50")
        #expect(requests[1].url?.path == "/plex/library/recentlyAdded")
        #expect(requests[2].url?.path == "/plex/library/metadata/movie + 42/extras")
    }

    @Test func accountProfilesNormalizeScalarsAndSwitchThroughClientsAPI() async throws {
        let transport = PlexStubTransport(#"{"authToken":"profile-token"}"#)
        let account = PlexAccountService(identity: try testIdentity(), transport: transport)
        let session = try await account.switchUser(uuid: "home + user", pin: "1+23", accountToken: "account-token")
        #expect(session.authToken == "profile-token")
        let request = try #require(await transport.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/api/v2/home/users/home + user/switch")
        #expect(request.url?.host == "clients.plex.tv")
        let components = try #require(request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) })
        #expect(components.queryItems?.first(where: { $0.name == "pin" })?.value == "1+23")
        #expect(request.value(forHTTPHeaderField: "X-Plex-Token") == "account-token")
        #expect(request.httpBody == nil)
        #expect(request.url?.absoluteString.contains("pin=1%2B23") == true)
        let user = try decodeFixture(
            PlexAccountUser.self,
            #"{"id":12,"uuid":"home-user","friendlyName":"Family","protected":"1"}"#
        )
        #expect(user.id == "12" && user.title == "Family" && user.isProtected)
    }

    @Test func accountAndHomeUsersUseAuthenticatedAccountOrigin() async throws {
        let transport = PlexStubTransport(#"{"users":[{"id":1,"title":"Home"}]}"#)
        let account = PlexAccountService(identity: try testIdentity(), transport: transport)
        #expect(try await account.homeUsers(accountToken: "account-token").first?.title == "Home")
        let request = try #require(await transport.requests.first)
        #expect(request.url?.host == "clients.plex.tv" && request.url?.path == "/api/v2/home/users")
        let profileTransport = PlexStubTransport(#"{"id":1,"username":"Owner"}"#)
        let profile = PlexAccountService(identity: try testIdentity(), transport: profileTransport)
        #expect(try await profile.user(accountToken: "account-token").title == "Owner")
    }
}
