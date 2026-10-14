import Foundation
@testable import Plex_Shared_Backend
import Testing

struct PlexRequestTests {
    @Test func buildsPaginatedLibraryRequestUnderProxyPath() throws {
        let page = try PlexPagination(start: 200, size: 50)
        let request = try PlexEndpoint.libraryItems(sectionID: "my library&?", page: page).makeRequest(configuration: testConfiguration())
        #expect(request.url?.absoluteString == "https://media.example/plex/library/sections/my%20library%26%3F/all?X-Plex-Container-Start=200&X-Plex-Container-Size=50")
        #expect(request.value(forHTTPHeaderField: "X-Plex-Token") == "server-token")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "X-Plex-Client-Profile-Name") == "Generic")
        #expect(request.cachePolicy == .reloadIgnoringLocalCacheData)
    }

    @Test func metadataIncludesDownloadAvailabilityAndStreams() throws {
        let request = try PlexEndpoint.metadata(ratingKey: "42").makeRequest(configuration: testConfiguration())
        let url = try #require(request.url)
        let query = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(Set(query.map(\.name)) == Set(["includeMarkers", "includeChapters", "checkFiles", "includeStreams"]))
        #expect(query.allSatisfy { $0.value == "1" })
    }

    @Test func handlesSharedLibraryAndDescendants() throws {
        let configuration = try testConfiguration()
        #expect(try PlexEndpoint.libraryItems(sectionID: "shared").makeRequest(configuration: configuration).url?.path == "/plex/library/shared/all")
        #expect(try PlexEndpoint.children(ratingKey: "42").makeRequest(configuration: configuration).url?.path == "/plex/library/metadata/42/children")
        #expect(try PlexEndpoint.grandchildren(ratingKey: "42").makeRequest(configuration: configuration).url?.path == "/plex/library/metadata/42/grandchildren")
    }

    @Test(arguments: ["", ".", "..", "a/b", "a\\b", "a\n"])
    func rejectsInvalidIDs(id: String) throws {
        #expect(throws: PlexAPIError.invalidPath) {
            try PlexEndpoint.metadata(ratingKey: id).makeRequest(configuration: testConfiguration())
        }
    }

    @Test(arguments: [
        "https://other.example/file", "//other.example/file", "/../file", "/%2e%2e/file", "/%252e%252e/file",
        "/a%2f..%2ffile", "/a%5cfile", "/a%0dfile", "/file#fragment", "/file?X-Plex-Token=other", "/file?%58-Plex-Token=other",
    ])
    func refusesUnsafeServerKeys(key: String) throws {
        #expect(throws: PlexAPIError.invalidPath) { try testConfiguration().request(path: key) }
    }

    @Test func preservesEscapesAndQueryFromServerKey() throws {
        let request = try testConfiguration().request(path: "/parts/a%20b.mkv?signature=a%2Bb+c&download=1")
        #expect(request.url?.absoluteString == "https://media.example/plex/parts/a%20b.mkv?signature=a%2Bb+c&download=1")
        #expect(request.url?.query?.contains("server-token") == false)
    }

    @Test(arguments: ["file:///tmp/media", "https://user:pass@media.example", "https://media.example?token=secret", "https://media.example/#fragment", "https://media.example/proxy/../"])
    func refusesInvalidBaseURLs(base: String) throws {
        #expect(throws: PlexAPIError.invalidConfiguration) { try testConfiguration(base: base) }
    }

    @Test func validatesIdentityTokenAndPagination() throws {
        #expect(throws: PlexAPIError.invalidConfiguration) {
            try PlexClientIdentity(identifier: "a\r\nb", product: "App", version: "1", platform: "iOS")
        }
        #expect(throws: PlexAPIError.invalidConfiguration) {
            try PlexServerConfiguration(baseURL: URL(string: "https://media.example")!, token: " ", identity: testIdentity())
        }
        #expect(throws: PlexAPIError.invalidPagination) { try PlexPagination(start: -1) }
        #expect(throws: PlexAPIError.invalidPagination) { try PlexPagination(size: 0) }
    }

    @Test(arguments: ["https://other.example/file", "http://media.example/file", "https://media.example:444/file", "https://user@media.example/file"])
    func refusesCredentialRedirects(destination: String) {
        #expect(!PlexRedirectPolicy.permits(from: URL(string: "https://media.example/plex"), to: URL(string: destination)))
    }

    @Test func permitsSameOriginRedirectWithDefaultPort() {
        #expect(PlexRedirectPolicy.permits(from: URL(string: "https://media.example/plex"), to: URL(string: "https://MEDIA.example:443/file")))
        #expect(!PlexRedirectPolicy.permits(from: nil, to: URL(string: "https://media.example")))
    }
}
