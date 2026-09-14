import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI
@available(iOS 17, *)
@Observable
@MainActor
final class SimilarTVViewModel {
    private(set) var state: LoadState<[SimilarTVShowEntity]> = .initial
    let apiService: any TMDBAPIRequesting
    let tvShowId: Int
    init(apiService: any TMDBAPIRequesting, tvShowId: Int) {
        self.apiService = apiService
        self.tvShowId = tvShowId
    }

    func load() async {
        guard state.isInitial else { return }
        state = .loading

        async let result: Result<TVShowListResultModel, TMDBAPIError> = apiService.request(.similarTVShows(show: tvShowId, page: nil))
        async let shows: TVShowListResultModel? = try? loadFavouriteTVList()
        let (similarListResult, favList) = await (result, shows)

        guard !Task.isCancelled else {
            state = .initial
            return
        }

        switch similarListResult {
        case let .success(similarList):
            let favouriteIds = Set(favList?.results.map(\.id) ?? [])
            let items = similarList.results.map { show in
                SimilarTVShowEntity(
                    tmdbImagePath: show.poster_path ?? show.backdrop_path ?? "",
                    title: show.name,
                    isFavorite: favList == nil ? nil : favouriteIds.contains(show.id),
                    showId: show.id
                )
            }
            state = .success(items)
        case let .failure(error):
            state = .error(error.localizedDescription)
        }
    }

    func loadFavouriteTVList() async throws -> TVShowListResultModel {
        let accountInfo: AccountInfoModel = try await apiService.request(.accountInfo)
        let shows: TVShowListResultModel = try await apiService.request(.getFavoriteTVShows(accountId: "\(accountInfo.id)"))
        return shows
    }

    func toggleFavorite(at index: Int) async {
    }
}

struct SimilarTVShowEntity: Identifiable {
    var id: Int { showId }

    let tmdbImagePath: String
    let title: String
    let isFavorite: Bool?
    let showId: Int
    static let placeholders: [SimilarTVShowEntity] = (0..<7).map { .placeholder(id: -$0) }
    static func placeholder(id: Int) -> SimilarTVShowEntity {
        return .init(tmdbImagePath: "", title: "Loading...", isFavorite: nil, showId: id)
    }
}
