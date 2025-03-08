import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend
// Creator struct for creators' information
fileprivate struct Creator {
    let name: String
    let imageURL: String
}

// Details struct for show details
fileprivate struct Details {
    let numberOfSeasons: Int
    let numberOfEpisodes: Int
    let firstAirDate: String
    let lastAirDate: String
    let status: String
    let averageVote: String
}

// Season struct, conforming to Identifiable
fileprivate struct Season: Identifiable {
    let id: String
    let name: String
    let posterURL: String
    let episodeCount: Int
    let airDate: String
}

// ShowData struct to hold all show information
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

fileprivate struct AppColors {
    static let primaryText = Color(UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1))  // #333333
    static let secondaryText = Color(UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)) // #666666
    static let background = Color(UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1)) // #f0f0f0
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text(showData.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primaryText)
                Text(showData.tagline)
                    .font(.title2)
                    .italic()
                    .foregroundColor(AppColors.secondaryText)

                // Main section
                HStack(alignment: .top, spacing: 20) {
                    // Show poster
                    AsyncImage(url: URL(string: showData.posterURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 150)

                    // Text information
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Overview")
                            .font(.headline)
                            .foregroundColor(AppColors.primaryText)
                        Text(showData.overview)
                            .font(.body)
                            .foregroundColor(AppColors.primaryText)

                        Text("Genres")
                            .font(.headline)
                            .foregroundColor(AppColors.primaryText)
                        Text(showData.genres)
                            .font(.body)
                            .foregroundColor(AppColors.primaryText)

                        Text("Created by")
                            .font(.headline)
                            .foregroundColor(AppColors.primaryText)
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
                                        .foregroundColor(AppColors.primaryText)
                                }
                            }
                        }

                        Text("Details")
                            .font(.headline)
                            .foregroundColor(AppColors.primaryText)
                        Text("Number of seasons: \(showData.details.numberOfSeasons)")
                            .font(.body)
                            .foregroundColor(AppColors.primaryText)
                        Text("Number of episodes: \(showData.details.numberOfEpisodes)")
                            .font(.body)
                            .foregroundColor(AppColors.primaryText)
                        Text("First air date: \(showData.details.firstAirDate)")
                            .font(.body)
                            .foregroundColor(AppColors.primaryText)
                        Text("Last air date: \(showData.details.lastAirDate)")
                            .font(.body)
                            .foregroundColor(AppColors.primaryText)
                        Text("Status: \(showData.details.status)")
                            .font(.body)
                            .foregroundColor(AppColors.primaryText)
                        Text("Average vote: \(showData.details.averageVote)")
                            .font(.body)
                            .foregroundColor(AppColors.primaryText)
                    }
                }

                // Seasons section
                Text("Seasons")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primaryText)

                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // First row (Seasons 1-4)
                        HStack(spacing: 20) {
                            ForEach(showData.seasons.prefix(4)) { season in
                                SeasonView(season: season)
                            }
                        }
                        // Second row (Seasons 5-8)
                        HStack(spacing: 20) {
                            ForEach(showData.seasons.suffix(4)) { season in
                                SeasonView(season: season)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

@available(iOS 15,*)
struct SeasonView: View {
    fileprivate let season: Season

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
                .foregroundColor(AppColors.primaryText)

            Text("\(season.episodeCount) episodes")
                .font(.caption2)
                .foregroundColor(AppColors.secondaryText)

            Text("Air date: \(season.airDate)")
                .font(.caption2)
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(width: 150)
        .padding(.bottom, 10)
        .background(AppColors.background)
        .cornerRadius(10)
    }
}

#if DEBUG
// swiftlint:disable all
@available(iOS 15,*)
#Preview {
    TVShowDetailLoadedView(tvShow: TVShowDetailModel.example)
        .environmentObject(ThemeManager.shared)
}
// swiftlint:enable all
#endif
