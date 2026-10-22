import CoreData
import CoreFeatures
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
    var persistentController: TMDBPersistentController
    var bookmarkedTVEntities: [TVBookmarkEntity] = []

    var persistentContext: NSManagedObjectContext {
        get {
            persistentController.container.viewContext
        }
    }

    init(apiService: any TMDBAPIRequesting,
         tvShowId: Int,
         persistentController: TMDBPersistentController? = nil) {
        self.apiService = apiService
        self.tvShowId = tvShowId
        if let p = persistentController {
            self.persistentController = p
        } else {
            self.persistentController = TMDBPersistentController()
        }
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
            await loadBookmarkTVItems()
            let items = similarList.results.map { show in
                SimilarTVShowEntity(
                    tmdbImagePath: show.poster_path ?? show.backdrop_path ?? "",
                    title: show.name,
                    isFavorite: favList == nil ? nil : favouriteIds.contains(show.id),
                    showId: show.id,
                    bookmarked: bookmarkedTVEntities.firstIndex{ $0.tv_id == show.id } != nil
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
        guard case .success(let shows) = state, shows.count > index else { return }
        await loadBookmarkTVItems()
        let existingBookmark = bookmarkedTVEntities.first{ $0.tv_id == shows[index].id }
        if let b = existingBookmark {
            persistentContext.delete(b)
        } else {
            let newBookmark = TVBookmarkEntity(context: persistentContext)
            newBookmark.tv_id = Int32(shows[index].id)
            newBookmark.created = Date()
        }
        await saveAndFetch()
    }

    private func saveAndFetch() async {
        do {
            try persistentContext.save()
        } catch {
            assertionFailure(error.localizedDescription)
        }
        await loadBookmarkTVItems()
    }

    func loadBookmarkTVItems() async {
        do {
            bookmarkedTVEntities = try persistentContext.fetch(TVBookmarkEntity.fetchRequest())
        } catch let err {
            assertionFailure(err.localizedDescription)
        }
    }
}

struct SimilarTVShowEntity: Identifiable {
    var id: Int { showId }

    let tmdbImagePath: String
    let title: String
    let isFavorite: Bool?
    let showId: Int
    let bookmarked: Bool
    static let placeholders: [SimilarTVShowEntity] = (0..<7).map { .placeholder(id: -$0) }
    static func placeholder(id: Int) -> SimilarTVShowEntity {
        return .init(tmdbImagePath: "", title: "Loading...", isFavorite: nil, showId: id, bookmarked: false)
    }
}
