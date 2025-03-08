import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

fileprivate struct Creator {
    let name: String
    let imageURL: String
}

fileprivate struct Details {
    let numberOfSeasons: Int
    let numberOfEpisodes: Int
    let firstAirDate: String
    let lastAirDate: String
    let status: String
    let averageVote: String
}

fileprivate struct Season: Identifiable {
    let id: String
    let name: String
    let posterURL: String
    let episodeCount: Int
    let airDate: String
}

fileprivate struct ShowData {
    let title: String
    let tagline: String
    let posterURL: String
    let overview: String
    let genres: String
    let creators: [Creator]
    let details: Details
    let seasons: [Season]
}

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
                averageVote: String(format: "%.1f (%d votes)", tvShow.voteAverage, tvShow.voteCount)
            ),
            seasons: tvShow.seasons.map { season in
                Season(
                    id: String(season.id),
                    name: season.name,
                    posterURL: season.posterPath.map { TMDBImageSize.small.buildImageUrl(path: $0).absoluteString } ?? "",
                    episodeCount: season.episodeCount,
                    airDate: season.airDate ?? "TBA"
                )
            }
        )
    }

    // Function to cycle through themes
    private func switchTheme() {
        let availableThemes = themeManager.availableThemes()
        guard let currentIndex = availableThemes.firstIndex(where: { $0.backgroundColor == themeManager.currentTheme.backgroundColor }) else { return }
        let nextIndex = (currentIndex + 1) % availableThemes.count
        themeManager.setTheme(availableThemes[nextIndex])
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
                        Text("Overview")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.labelColor)
                        Text(showData.overview)
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.labelColor)

                        Text("Genres")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.labelColor)
                        Text(showData.genres)
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.labelColor)

                        Text("Created by")
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

                        Text("Details")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.labelColor)
                        Text("Number of seasons: \(showData.details.numberOfSeasons)")
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.labelColor)
                        Text("Number of episodes: \(showData.details.numberOfEpisodes)")
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.labelColor)
                        Text("First air date: \(showData.details.firstAirDate)")
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.labelColor)
                        Text("Last air date: \(showData.details.lastAirDate)")
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.labelColor)
                        Text("Status: \(showData.details.status)")
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.labelColor)
                        Text("Average vote: \(showData.details.averageVote)")
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.labelColor)
                    }
                }

                Text("Seasons")
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
        .navigationBarItems(trailing: Button(action: {
            switchTheme()
        }) {
            Image(systemName: "arrow.trianglehead.swap")
                .foregroundColor(themeManager.currentTheme.labelColor)
        })
    }
}

@available(iOS 15, *)
struct SeasonView: View {
    fileprivate let season: Season
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading) {
            AsyncImage(url: URL(string: season.posterURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 150, height: 225)

            Text(season.name)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.labelColor)

            Text("\(season.episodeCount) episodes")
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.labelColor.opacity(0.7)) // Secondary text effect

            Text("Air date: \(season.airDate)")
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.labelColor.opacity(0.7)) // Secondary text effect
        }
        .frame(width: 150)
        .padding(.bottom, 10)
        .background(themeManager.currentTheme.backgroundColor) // Use theme background
        .cornerRadius(10)
    }
}

#if DEBUG
@available(iOS 15, *)
#Preview {
    TVShowDetailLoadedView(tvShow: TVShowDetailModel.example)
        .environmentObject(ThemeManager.shared)
}
#endif
