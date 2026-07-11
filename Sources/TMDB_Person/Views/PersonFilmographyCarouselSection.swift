import Shared_UI_Support
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 18.0, *)
struct PersonFilmographyCarouselSection<Route: Hashable>: View {
    let credits: [PersonMovieCredit]
    let movieRouteBuilder: (Int) -> Route

    @State private var currentPage: Int? = 0

    private var carouselItems: [PersonMovieCredit] {
        Array(credits.prefix(40))
    }

    private let posterWidth: CGFloat = 180
    private let posterHeight: CGFloat = 270

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringResource.personFilmography)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

            if carouselItems.isEmpty {
                Text(LocalizedStringResource.personNoMovieCredits)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                CoverFlow(
                    config: CoverFlowConfig(cardWidth: posterWidth, activeElevation: 50),
                    currentPage: $currentPage
                ) {
                    ForEach(carouselItems, id: \.id) { credit in
                        NavigationLink(value: movieRouteBuilder(credit.id)) {
                            RemoteTMDBImage(
                                posterPath: credit.posterPath,
                                posterSize: PosterSize(width: posterWidth, height: posterHeight),
                                imageSize: .posterLarge
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(credit.title)
                    }
                }
                .frame(height: posterHeight)
                .accessibilityIdentifier("personDetail.filmography.carousel")

                if let currentPage, carouselItems.indices.contains(currentPage) {
                    Text(carouselItems[currentPage].title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .accessibilityIdentifier("personDetail.filmography.activeTitle")
                }
            }
        }
    }
}
