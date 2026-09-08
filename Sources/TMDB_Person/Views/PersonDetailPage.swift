import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

@available(iOS 16.0, *)
public struct PersonDetailPage<Route: Hashable>: View {
    private let personId: Int
    private let movieRouteBuilder: (Int) -> Route
    @StateObject private var store: PersonDetailViewModel
    @State private var useCarouselFilmography = false

    public init(
        personId: Int,
        apiService: TMDBAPIService,
        movieRouteBuilder: @escaping (Int) -> Route
    ) {
        self.personId = personId
        self.movieRouteBuilder = movieRouteBuilder
        _store = StateObject(wrappedValue: PersonDetailViewModel(apiService: apiService, personId: personId))
    }

    public var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                SwitchDesignToolbarItem(accessibilityIdentifier: "personDetail.switchDesign.button") {
                    useCarouselFilmography.toggle()
                }
            }
            .task(id: personId) {
                await store.load()
            }
            .refreshable {
                await store.reload()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .initial, .loading:
            ProgressView {
                Text(LocalizedStringResource.personLoading)
            }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let payload):
            PersonDetailContent(
                person: payload.detail,
                credits: payload.credits.featuredCredits,
                useCarouselFilmography: useCarouselFilmography,
                movieRouteBuilder: movieRouteBuilder
            )
        case .error(let message):
            PersonErrorStateView(message: message) {
                Task { await store.reload() }
            }
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
#Preview {
    NavigationStack {
        PersonDetailPage(
            personId: 287,
            apiService: TMDBAPIService(apiKey: debugTMDBAPIKey),
            movieRouteBuilder: { $0 }
        )
    }
}
#endif
