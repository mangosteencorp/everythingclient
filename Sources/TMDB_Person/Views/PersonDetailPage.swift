import SwiftUI
import TMDB_Shared_Backend

@available(iOS 16.0, *)
public struct PersonDetailPage<Route: Hashable>: View {
    private struct LoadedPayload {
        let detail: PersonDetail
        let credits: PersonMovieCredits
    }

    private enum ViewState {
        case loading
        case loaded(LoadedPayload)
        case error(String)
    }

    private final class Store: ObservableObject {
        @Published var state: ViewState = .loading

        private let apiService: TMDBAPIService
        private let personId: Int

        init(apiService: TMDBAPIService, personId: Int) {
            self.apiService = apiService
            self.personId = personId
        }

        func fetch() async {
            await MainActor.run {
                state = .loading
            }
            do {
                let detail: PersonDetail = try await apiService.request(.personDetail(person: personId))
                let credits: PersonMovieCredits = try await apiService.request(.personMovieCredits(person: personId))
                await MainActor.run {
                    state = .loaded(LoadedPayload(detail: detail, credits: credits))
                }
            } catch {
                await MainActor.run {
                    state = .error(error.localizedDescription)
                }
            }
        }
    }

    private let personId: Int
    private let movieRouteBuilder: (Int) -> Route
    @StateObject private var store: Store

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
            .navigationBarTitleDisplayMode(.inline)
            .task(id: personId) {
                await store.fetch()
            }
            .refreshable {
                await store.fetch()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .loading:
            ProgressView {
                Text(LocalizedStringResource.personLoading)
            }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let payload):
            PersonDetailContent(
                person: payload.detail,
                credits: payload.credits.featuredCredits,
                movieRouteBuilder: movieRouteBuilder
            )
        case .error(let message):
            PersonErrorStateView(message: message) {
                Task { await store.fetch() }
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
