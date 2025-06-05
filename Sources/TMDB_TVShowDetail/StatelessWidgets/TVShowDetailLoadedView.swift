import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

@available(iOS 15, *)
struct TVShowDetailLoadedView: View {
    let tvShow: TVShowDetailModel
    @EnvironmentObject var themeManager: ThemeManager

    private var showData: ShowData {
        ShowData(
            title: tvShow.name,
            tagline: tvShow.tagline,
            posterURL: TMDBImageSize.medium.buildImageUrl(path: tvShow.posterPath ?? "").absoluteString,
            overview: tvShow.overview,
            genres: tvShow.genres.map { $0.name }.joined(separator: ", "),
            creators: tvShow.createdBy.map { creator in
                Creator(
                    name: creator.name,
                    imageURL: creator.profilePath.map { TMDBImageSize.cast.buildImageUrl(path: $0).absoluteString } ?? ""
                )
            },
            details: Details(
                numberOfSeasons: tvShow.numberOfSeasons,
                numberOfEpisodes: tvShow.numberOfEpisodes,
                firstAirDate: tvShow.firstAirDate,
                lastAirDate: tvShow.lastAirDate,
                status: tvShow.status,
                averageVote: L10n.Tvshow.Detail.averageVote(Float(tvShow.voteAverage), tvShow.voteCount)
            ),
            seasons: tvShow.seasons.map { season in
                Season(
                    id: String(season.id),
                    name: season.name,
                    posterURL: season.posterPath.map { TMDBImageSize.small.buildImageUrl(path: $0).absoluteString } ?? "",
                    episodeCount: season.episodeCount,
                    airDate: season.airDate ?? L10n.Tvshow.Detail.tba
                )
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(showData.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.labelColor)
                Text(showData.tagline)
                    .font(.title2)
                    .italic()
                    .foregroundColor(themeManager.currentTheme.labelColor.opacity(0.7)) // Secondary text effect

                HStack(alignment: .top, spacing: 20) {
                    AsyncImage(url: URL(string: showData.posterURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 150)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.Tvshow.Detail.overview)
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.labelColor)
                        Text(showData.overview)
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.labelColor)

                        Text(L10n.Tvshow.Detail.genres)
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.labelColor)
                        Text(showData.genres)
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.labelColor)

                        Text(L10n.Tvshow.Detail.createdBy)
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.labelColor)
                        HStack(spacing: 20) {
                            ForEach(showData.creators, id: \.name) { creator in
                                VStack {
                                    AsyncImage(url: URL(string: creator.imageURL)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    Text(creator.name)
                                        .font(.caption)
                                        .foregroundColor(themeManager.currentTheme.labelColor)
                                }
                            }
                        }

                        Text(L10n.Tvshow.Detail.details)
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.labelColor)
                        Text(L10n.Tvshow.Detail.numberOfSeasons(showData.details.numberOfSeasons))
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.labelColor)
                        Text(L10n.Tvshow.Detail.numberOfEpisodes(showData.details.numberOfEpisodes))
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.labelColor)
                        Text(L10n.Tvshow.Detail.firstAirDate(showData.details.firstAirDate))
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.labelColor)
                        Text(L10n.Tvshow.Detail.lastAirDate(showData.details.lastAirDate))
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.labelColor)
                        Text(L10n.Tvshow.Detail.status(showData.details.status))
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.labelColor)
                        Text(showData.details.averageVote)
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.labelColor)
                    }
                }

                Text(L10n.Tvshow.Detail.seasons)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.labelColor)

                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 20) {
                        HStack(spacing: 20) {
                            ForEach(showData.seasons.prefix(4)) { season in
                                SeasonView(season: season)
                            }
                        }
                        HStack(spacing: 20) {
                            ForEach(showData.seasons.suffix(4)) { season in
                                SeasonView(season: season)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(themeManager.currentTheme.backgroundColor) // Apply background color to the entire view
        }
        .navigationBarItems(trailing: ThemeSwitchButton())
    }
}

#if DEBUG
@available(iOS 15, *)
#Preview {
    TVShowDetailLoadedView(tvShow: TVShowDetailModel.example)
        .environmentObject(ThemeManager.shared)
}
#endif
