import Shared_UI_Support
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 16.0, *)
struct PersonFilmographyCarouselCredit: Identifiable, StackedPosterCarouselTitled {
    let credit: PersonMovieCredit

    var id: Int { credit.id }
    var carouselTitle: String { credit.title }
}

@available(iOS 16.0, *)
struct PersonFilmographyCarouselSection<Route: Hashable>: View {
    let credits: [PersonMovieCredit]
    let movieRouteBuilder: (Int) -> Route

    @State private var selectedIndex = 0

    private var carouselItems: [PersonFilmographyCarouselCredit] {
        credits.prefix(40).map { PersonFilmographyCarouselCredit(credit: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if credits.isEmpty {
                Text(LocalizedStringResource.personNoMovieCredits)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ZStack(alignment: .leading) {
                    StackedPosterCarouselView(
                        title: String(localized: LocalizedStringResource.personFilmography),
                        items: carouselItems,
                        selectedIndex: $selectedIndex
                    ) { item in
                        RemoteTMDBImage(
                            posterPath: item.credit.posterPath,
                            posterSize: PosterSize(width: 180, height: 270),
                            imageSize: .posterLarge
                        )
                    }

                    if carouselItems.indices.contains(selectedIndex) {
                        let credit = carouselItems[selectedIndex].credit
                        NavigationLink(value: movieRouteBuilder(credit.id)) {
                            Color.clear
                                .frame(width: 180, height: 270)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(credit.title)
                    }
                }
                .accessibilityIdentifier("personDetail.filmography.carousel")
            }
        }
    }
}
