#if DEBUG
import Foundation
import RSS_Shared_Backend

/// Offline, silent mode for tests and previews: a bundled copy of IGN's feed, and an audio engine that makes no sound.
enum DemoFixtures {
    /// UI tests launch the app with this argument.
    static let launchArgument = "-PodcastDemoFixtures"

    /// Also on while the app hosts unit tests, so they never download the real feed.
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
            || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}

/// Serves the trimmed IGN feed bundled with the app whatever URL is asked for, or throws `error` when set.
nonisolated struct FixtureRSSFeedProvider: RSSFeedProviding {
    var error: (any Error)?

    func feed(at _: URL) async throws -> RSSFeed {
        if let error { throw error }
        guard let url = Bundle.main.url(forResource: "ign-movie-review", withExtension: "xml") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try RSSParser().parse(Data(contentsOf: url))
    }
}
#endif
