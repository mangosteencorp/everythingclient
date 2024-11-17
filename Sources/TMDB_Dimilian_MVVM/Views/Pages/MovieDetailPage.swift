import SwiftUI
struct MovieDetailPage: View {
    let movie: Movie
    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                Section {
                    MovieCoverRow(movie: movie)
                    // TODO: Button rows: Wishlist, Seenlist, list
                    MovieOverview(movie: movie)
                }
                Section {
                    MovieKeywords(keywords: movie.keywords?.keywords ?? [])
                    MovieCreditSection(movieId: movie.id)
                }
            }
            .navigationBarTitle(Text(movie.userTitle), displayMode: .large)
            // TODO: .navigationBarItems(trailing: Button(action: onAddButton) "text.badge.plus"
            // Movie Poster row
        }
    }
}
