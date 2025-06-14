import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

enum TVShowDetailViewState {
    case loading
    case loaded(TVShowDetailModel)
    case error(Error)
}

@available(iOS 15, *)
public struct TVShowDetailView: View {
    @StateObject private var store: TVShowDetailStore

    public init(apiService: TMDBAPIService, tvShowId: Int) {
        _store = StateObject(wrappedValue: TVShowDetailStore(apiService: apiService, tvShowId: tvShowId))
    }

    public var body: some View {
        Group {
            switch store.state {
            case .loading:
                LoadingView()
            case .loaded(let tvShow):
                TVShowDetailLoadedView(tvShow: tvShow)
            case .error(let error):
                Text(L10n.Tvshow.Detail.error(error))
            }
        }
        .task {
            await store.fetchTVShowDetail()
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text(L10n.Tvshow.Detail.loading)
                .foregroundColor(.gray)
        }
    }
}

#if DEBUG
@available(iOS 15, *)
#Preview { // FIXME: preview broken
    TVShowDetailView(apiService:
                        TMDBAPIService(apiKey:
                                        debugTMDBAPIKey
                                      ),
                     tvShowId: 1399) // Game of Thrones ID
        .environmentObject(ThemeManager.shared)
}
#endif
