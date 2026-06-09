import SwiftUI
import TMDB_Shared_Backend

@available(iOS 16.0, *)
struct PersonFilmographySection<Route: Hashable>: View {
    let credits: [PersonMovieCredit]
    let movieRouteBuilder: (Int) -> Route

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringResource.personFilmography)
                .font(.headline)

            if credits.isEmpty {
                Text(LocalizedStringResource.personNoMovieCredits)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(credits.prefix(40)) { credit in
                        NavigationLink(value: movieRouteBuilder(credit.id)) {
                            PersonMovieCreditRow(credit: credit)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
