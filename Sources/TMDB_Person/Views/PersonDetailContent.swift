import SwiftUI
import TMDB_Shared_Backend

@available(iOS 16.0, *)
struct PersonDetailContent<Route: Hashable>: View {
    let person: PersonDetail
    let credits: [PersonMovieCredit]
    let useCarouselFilmography: Bool
    let movieRouteBuilder: (Int) -> Route

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PersonDetailHeaderView(person: person)
                PersonFactGrid(person: person)
                PersonBiographySection(biography: person.biography)

                if useCarouselFilmography {
                    PersonFilmographyCarouselSection(
                        credits: credits,
                        movieRouteBuilder: movieRouteBuilder
                    )
                } else {
                    PersonFilmographySection(
                        credits: credits,
                        movieRouteBuilder: movieRouteBuilder
                    )
                    .accessibilityIdentifier("personDetail.filmography.list")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(person.name)
    }
}
