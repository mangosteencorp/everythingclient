import SwiftUI
import TMDB_Shared_Backend

@available(iOS 16.0, *)
struct PersonDetailContent<Route: Hashable>: View {
    let person: PersonDetail
    let credits: [PersonMovieCredit]
    let movieRouteBuilder: (Int) -> Route
    @State private var isSwiftfinPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PersonDetailHeaderView(person: person)
                PersonFactGrid(person: person)
                PersonBiographySection(biography: person.biography)
                PersonFilmographySection(credits: credits, movieRouteBuilder: movieRouteBuilder)
                Button {
                    isSwiftfinPresented = true
                } label: {
                    Label("Launch Swiftfin", systemImage: "play.rectangle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(person.name)
        .fullScreenCover(isPresented: $isSwiftfinPresented) {
            SwiftfinLaunchView()
        }
    }
}
