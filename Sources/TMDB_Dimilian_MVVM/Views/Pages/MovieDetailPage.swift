import SwiftUI
struct MovieDetailPage: View {
    let movieId: Int
    var body: some View {
        VStack {
            MovieCreditSection(movieId: movieId)
        }
    }
}
