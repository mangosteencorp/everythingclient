import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

@available(iOS 16.0, *)
public struct PersonDetailPage<Route: Hashable>: View {
    private struct LoadedPayload {
        let detail: PersonDetail
        let credits: PersonMovieCredits
    }

    private enum ViewState {
        case initial
        case loading
        case loaded(LoadedPayload)
        case error(String)

        var isInitial: Bool {
            if case .initial = self { return true }
            return false
        }

        var isLoading: Bool {
            if case .loading = self { return true }
            return false
        }
    }

    @MainActor
    private final class Store: ObservableObject {
        @Published var state: ViewState = .initial

        private let apiService: TMDBAPIService
        private let personId: Int

        init(apiService: TMDBAPIService, personId: Int) {
            self.apiService = apiService
            self.personId = personId
        }

        /// Entry point for `.task`: nothing happens unless this person has never been loaded.
        func load() async {
            guard state.isInitial else { return }
            await fetch()
        }

        /// Pull to refresh and the error view's retry. Refuses to stack on an in-flight request.
        func reload() async {
            guard !state.isLoading else { return }
            await fetch()
        }

        private func fetch() async {
            state = .loading
            do {
                let detail: PersonDetail = try await apiService.request(.personDetail(person: personId))
                let credits: PersonMovieCredits = try await apiService.request(.personMovieCredits(person: personId))
                state = .loaded(LoadedPayload(detail: detail, credits: credits))
            } catch {
                // Backing out of the page cancels the requests; `initial` lets the next appearance
                // load again instead of showing a cancellation as a failure.
                guard !Task.isCancelled else {
                    state = .initial
                    return
                }
                state = .error(error.localizedDescription)
            }
        }
    }

    private let personId: Int
    private let movieRouteBuilder: (Int) -> Route
    @StateObject private var store: Store
    @State private var useCarouselFilmography = false

    public init(
        personId: Int,
        apiService: TMDBAPIService,
        movieRouteBuilder: @escaping (Int) -> Route
    ) {
        self.personId = personId
        self.movieRouteBuilder = movieRouteBuilder
        _store = StateObject(wrappedValue: Store(apiService: apiService, personId: personId))
    }

    public var body: some View {
        content
            .platformNavigationBarTitleDisplayMode(.inline)
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
