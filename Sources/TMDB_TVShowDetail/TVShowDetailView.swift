import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 15, *)
public struct TVShowDetailView: View {
    // MARK: - Dependencies

    private let apiService: TMDBAPIService
    @EnvironmentObject private var themeManager: ThemeManager

    // MARK: - View State (No ViewModel needed!)

    enum ViewState {
        case loading
        case loaded(TVShowDetailModel)
        case error(String)
    }

    // MARK: - Properties

    let tvShowId: Int
    @State private var viewState: ViewState = .loading
    @State private var isRefreshing = false

    // MARK: - Initialization

    public init(tvShowId: Int, apiService: TMDBAPIService) {
        self.tvShowId = tvShowId
        self.apiService = apiService
    }

    // MARK: - Body

    public var body: some View {
        NavigationView {
            contentView
                .refreshable {
                    await refreshTVShowDetail()
                }
                .task(id: tvShowId) {
                    await loadTVShowDetail()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ThemeSwitchButton()
                    }
                }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch viewState {
        case .loading:
            LoadingStateView()
        case .loaded(let tvShow):
            TVShowDetailContentView(tvShow: tvShow)
        case .error(let message):
            ErrorStateView(
                message: message,
                retryAction: { await loadTVShowDetail() }
            )
        }
    }

    // MARK: - Data Loading

    private func loadTVShowDetail() async {
        viewState = .loading
        do {
            let result: TVShowDetailModel = try await apiService.request(.tvShowDetail(show: tvShowId))
            viewState = .loaded(result)
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }

    private func refreshTVShowDetail() async {
        defer { isRefreshing = false }
        isRefreshing = true
        await loadTVShowDetail()
    }
}

// MARK: - Loading State View

@available(iOS 15, *)
struct LoadingStateView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(themeManager.currentTheme.labelColor)

            Text(L10n.Tvshow.Detail.loading)
                .foregroundColor(themeManager.currentTheme.labelColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.currentTheme.backgroundColor)
    }
}

// MARK: - Error State View

@available(iOS 15, *)
struct ErrorStateView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let message: String
    let retryAction: () async -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(themeManager.currentTheme.labelColor.opacity(0.6))

            Text("Something went wrong")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.labelColor)

            Text(message)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.labelColor.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Try Again") {
                Task { await retryAction() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.currentTheme.backgroundColor)
    }
}

// MARK: - Main Content View

@available(iOS 15, *)
struct TVShowDetailContentView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let tvShow: TVShowDetailModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TVShowHeaderView(tvShow: tvShow)
                TVShowInfoView(tvShow: tvShow)
                TVShowSeasonsView(tvShow: tvShow)
            }
            .padding()
        }
        .background(themeManager.currentTheme.backgroundColor)
    }
}

// MARK: - Header View

@available(iOS 15, *)
struct TVShowHeaderView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let tvShow: TVShowDetailModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(tvShow.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.labelColor)

            if !tvShow.tagline.isEmpty {
                Text(tvShow.tagline)
                    .font(.title2)
                    .italic()
                    .foregroundColor(themeManager.currentTheme.labelColor.opacity(0.7))
            }
        }
    }
}

// MARK: - Info View

@available(iOS 15, *)
struct TVShowInfoView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let tvShow: TVShowDetailModel

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            PosterImageView(posterPath: tvShow.posterPath)

            VStack(alignment: .leading, spacing: 16) {
                TVShowOverviewSection(overview: tvShow.overview)
                TVShowGenresSection(genres: tvShow.genres)
                TVShowCreatorsSection(creators: tvShow.createdBy)
                TVShowDetailsSection(tvShow: tvShow)
            }
        }
    }
}

// MARK: - Poster Image View

@available(iOS 15, *)
struct PosterImageView: View {
    let posterPath: String?

    var body: some View {
        AsyncImage(url: posterURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        } placeholder: {
            ProgressView()
                .frame(width: 150, height: 225)
        }
        .frame(width: 150)
        .cornerRadius(12)
    }

    private var posterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return TMDBImageSize.medium.buildImageUrl(path: posterPath)
    }
}

// MARK: - Overview Section

@available(iOS 15, *)
struct TVShowOverviewSection: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let overview: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Tvshow.Detail.overview)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.labelColor)

            Text(overview)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.labelColor)
        }
    }
}

// MARK: - Genres Section

@available(iOS 15, *)
struct TVShowGenresSection: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let genres: [GenreModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Tvshow.Detail.genres)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.labelColor)

            Text(genres.map { $0.name }.joined(separator: ", "))
                .font(.body)
                .foregroundColor(themeManager.currentTheme.labelColor)
        }
    }
}

// MARK: - Creators Section

@available(iOS 15, *)
struct TVShowCreatorsSection: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let creators: [TVShowDetailModel.Creator]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Tvshow.Detail.createdBy)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.labelColor)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(creators, id: \.id) { creator in
                        CreatorView(creator: creator)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
}

// MARK: - Creator View

@available(iOS 15, *)
struct CreatorView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let creator: TVShowDetailModel.Creator

    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: profileImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())

            Text(creator.name)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.labelColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 70)
    }

    private var profileImageURL: URL? {
        guard let profilePath = creator.profilePath else { return nil }
        return TMDBImageSize.cast.buildImageUrl(path: profilePath)
    }
}

// MARK: - Details Section

@available(iOS 15, *)
struct TVShowDetailsSection: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let tvShow: TVShowDetailModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Tvshow.Detail.details)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.labelColor)

            VStack(alignment: .leading, spacing: 4) {
                DetailRow(
                    title: L10n.Tvshow.Detail.numberOfSeasons(tvShow.numberOfSeasons)
                )
                DetailRow(
                    title: L10n.Tvshow.Detail.numberOfEpisodes(tvShow.numberOfEpisodes)
                )
                DetailRow(
                    title: L10n.Tvshow.Detail.firstAirDate(tvShow.firstAirDate)
                )
                DetailRow(
                    title: L10n.Tvshow.Detail.lastAirDate(tvShow.lastAirDate)
                )
                DetailRow(
                    title: L10n.Tvshow.Detail.status(tvShow.status)
                )
                DetailRow(
                    title: L10n.Tvshow.Detail.averageVote(Float(tvShow.voteAverage), tvShow.voteCount)
                )
            }
        }
    }
}

// MARK: - Detail Row

@available(iOS 15, *)
struct DetailRow: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let title: String

    var body: some View {
        Text(title)
            .font(.body)
            .foregroundColor(themeManager.currentTheme.labelColor)
    }
}

// MARK: - Seasons View

@available(iOS 15, *)
struct TVShowSeasonsView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let tvShow: TVShowDetailModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.Tvshow.Detail.seasons)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.labelColor)

            if tvShow.seasons.count > 4 {
                seasonGridView
            } else {
                seasonRowView
            }
        }
    }

    private var seasonRowView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(tvShow.seasons, id: \.id) { season in
                    SeasonCardView(season: season)
                }
            }
            .padding(.horizontal, 1)
        }
    }

    private var seasonGridView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ForEach(tvShow.seasons.prefix(8), id: \.id) { season in
                SeasonCardView(season: season)
            }
        }
    }
}

// MARK: - Season Card View

@available(iOS 15, *)
struct SeasonCardView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let season: TVShowDetailModel.Season

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: seasonPosterURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(2/3, contentMode: .fit)
                    .overlay {
                        Image(systemName: "tv")
                            .foregroundColor(.gray)
                    }
            }
            .frame(width: 100)
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(season.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.labelColor)
                    .lineLimit(2)

                Text("\(season.episodeCount) episodes")
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.labelColor.opacity(0.7))

                if let airDate = season.airDate {
                    Text(airDate)
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.labelColor.opacity(0.7))
                }
            }
        }
        .frame(width: 120)
    }

    private var seasonPosterURL: URL? {
        guard let posterPath = season.posterPath else { return nil }
        return TMDBImageSize.small.buildImageUrl(path: posterPath)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text(L10n.Tvshow.Detail.loading)
                .foregroundColor(.gray)
        }
    }
}

#if DEBUG
@available(iOS 15, *)
#Preview {
    TVShowDetailView(tvShowId: 1399, apiService: TMDBAPIService(apiKey: debugTMDBAPIKey))
        .environmentObject(ThemeManager.shared)
}
#endif
