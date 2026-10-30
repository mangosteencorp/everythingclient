import Podcast_Player
import Podcast_Shared_UI
import RSS_Shared_Backend
import SwiftUI

/// IGN's reviews, newest first. Typing a movie's full title puts its review on top; tapping an episode plays it in
/// the mini player at the bottom.
struct PodcastReviewsView: View {
    @Bindable var model: PodcastReviewsModel
    let player: PodcastPlayer

    var body: some View {
        content
            .navigationTitle(Text(.reviewsTitle))
            .searchable(text: $model.searchText, prompt: Text(.searchPrompt))
            .task {
                // Tabs re-run this on every visit; only the first one downloads.
                if model.state == .loading { await model.load() }
            }
            .safeAreaInset(edge: .bottom) {
                if let episode = player.currentEpisode {
                    PodcastEpisodeCard(episode: episode, player: player)
                        .padding(.horizontal)
                        .background(.bar)
                        .accessibilityIdentifier("podcastDemo.miniPlayer")
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            ProgressView { Text(.loadingReviews) }
        case let .failed(message):
            ContentUnavailableView {
                Label { Text(.loadFailedTitle) } icon: { Image(systemName: "wifi.exclamationmark") }
            } description: {
                Text(message)
            } actions: {
                Button { Task { await model.retry() } } label: { Text(.retry) }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("podcastDemo.retry")
            }
        case .loaded:
            episodeList
        }
    }

    private var episodeList: some View {
        List {
            if let review = model.matchedReview {
                Section {
                    PodcastEpisodeCard(episode: review, player: player)
                        .accessibilityIdentifier("podcastDemo.matchedReview")
                } header: {
                    Text(.matchedReviewHeader)
                }
            }
            Section {
                ForEach(model.filteredEpisodes) { episode in
                    Button { player.play(episode) } label: { PodcastEpisodeRow(episode: episode) }
                        // Reads as content rather than as an accent-coloured link.
                        .tint(.primary)
                        .accessibilityIdentifier("podcastDemo.episode")
                }
            } header: {
                Text(.episodesHeader)
            }
        }
        .overlay {
            if model.matchedReview == nil, model.filteredEpisodes.isEmpty {
                ContentUnavailableView.search(text: model.searchText)
            }
        }
        .refreshable { await model.load() }
    }
}

#if DEBUG
#Preview("Loaded") {
    NavigationStack {
        PodcastReviewsView(model: PodcastReviewsModel(feedProvider: FixtureRSSFeedProvider()), player: .preview())
    }
}

#Preview("Playing") {
    NavigationStack {
        PodcastReviewsView(
            model: PodcastReviewsModel(feedProvider: FixtureRSSFeedProvider()),
            player: .preview(.playing, elapsed: 125)
        )
    }
}

#Preview("Failed") {
    NavigationStack {
        PodcastReviewsView(
            model: PodcastReviewsModel(feedProvider: FixtureRSSFeedProvider(error: URLError(.notConnectedToInternet))),
            player: .preview()
        )
    }
}
#endif
