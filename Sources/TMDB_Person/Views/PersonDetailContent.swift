import SwiftUI
import TMDB_Shared_Backend

@available(iOS 16.0, *)
struct PersonDetailContent<Route: Hashable>: View {
    let person: PersonDetail
    let credits: [PersonMovieCredit]
    let movieRouteBuilder: (Int) -> Route

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PersonDetailHeaderView(person: person)
                PersonFactGrid(person: person)
                PersonBiographySection(biography: person.biography)
                PersonFilmographySection(credits: credits, movieRouteBuilder: movieRouteBuilder)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(person.name)
    }
}
