import Podcast_Player
import RSS_Shared_Backend
import SwiftUI

@main
struct PodcastDemoApp: App {
    @State private var model: PodcastReviewsModel
    @State private var player: PodcastPlayer

    init() {
        #if DEBUG
        if DemoFixtures.isEnabled {
            _model = State(initialValue: PodcastReviewsModel(feedProvider: FixtureRSSFeedProvider()))
            _player = State(initialValue: PodcastPlayer(engine: PodcastSilentAudioEngine()))
            return
        }
        #endif
        // No cache: the demo has one screen, and pulling to refresh should download the feed again.
        _model = State(initialValue: PodcastReviewsModel(feedProvider: RSSFeedService(timeToLive: .zero)))
        _player = State(initialValue: PodcastPlayer())
    }

    var body: some Scene {
        WindowGroup {
            DemoTabs(model: model, player: player)
        }
    }
}

/// The reviews, and in debug builds every podcast component preview.
struct DemoTabs: View {
    let model: PodcastReviewsModel
    let player: PodcastPlayer

    var body: some View {
        TabView {
            Tab(String(localized: .reviewsTitle), systemImage: "mic") {
                NavigationStack {
                    PodcastReviewsView(model: model, player: player)
                }
            }
            #if DEBUG
            Tab(String(localized: .componentsTitle), systemImage: "square.grid.2x2") {
                NavigationStack {
                    PodcastCatalogView()
                }
            }
            #endif
        }
    }
}

#if DEBUG
#Preview {
    DemoTabs(model: PodcastReviewsModel(feedProvider: FixtureRSSFeedProvider()), player: .preview())
}
#endif
