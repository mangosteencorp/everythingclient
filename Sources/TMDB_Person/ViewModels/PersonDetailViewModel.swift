import Foundation
import TMDB_Shared_Backend

/// The person detail and their credits, loaded together so the page renders in one step.
struct PersonDetailPayload {
    let detail: PersonDetail
    let credits: PersonMovieCredits
}

enum PersonDetailState {
    case initial
    case loading
    case loaded(PersonDetailPayload)
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

/// Lifted out of `PersonDetailPage` so the loading rules — load once, retry on demand, treat a
/// cancellation as "not loaded yet" — can be tested without standing up the SwiftUI page.
@MainActor
final class PersonDetailViewModel: ObservableObject {
    @Published private(set) var state: PersonDetailState = .initial

    private let apiService: any TMDBAPIRequesting
    private let personId: Int

    init(apiService: any TMDBAPIRequesting, personId: Int) {
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
            state = .loaded(PersonDetailPayload(detail: detail, credits: credits))
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
