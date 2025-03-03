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
struct TVShowDetailView: View {
    //@EnvironmentObject var themeManager: ThemeManager
    var apiService: TMDBAPIService
    let tvShowId: Int

    @State private var viewState: TVShowDetailViewState = .loading

    var body: some View {
        Group {
            switch viewState {
            case .loading:
                LoadingView()
            case .loaded(let tvShow):
                TVShowDetailLoadedView(tvShow: tvShow)
            case .error:
                Text("Error")
            }
        }
        .task {
            await loadTVShowDetail()
        }
    }

    private func loadTVShowDetail() async {
        do {
            let result: TVShowDetailModel = try await apiService.request(.tvShowDetail(show: tvShowId))
            viewState = .loaded(result)
        } catch {
            viewState = .error(error)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading TV Show Details...")
                .foregroundColor(.gray)
        }
    }
}
#if DEBUG
@available(iOS 15,*)
#Preview {
    TVShowDetailView(apiService:
                        TMDBAPIService(apiKey:
                                        ""
                                      ),
                     tvShowId: 1399) // Game of Thrones ID
        //.environmentObject(ThemeManager.shared)
}
#endif
