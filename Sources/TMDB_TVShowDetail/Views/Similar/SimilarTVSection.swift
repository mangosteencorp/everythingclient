import Shared_UI_Support
import SwiftUI
import TMDB_Shared_UI
@available(iOS 17, *) // to use Observable
struct SimilarTVSection: View {
    @State var viewModel: SimilarTVViewModel
    private var isPlaceholder: Bool {
        viewModel.state.isInitial || viewModel.state.isLoading
    }

    private var displayedItems: [SimilarTVShowEntity] {
        viewModel.state.value ?? SimilarTVShowEntity.placeholders
    }

    var body: some View {
        VStack(alignment: .leading){
            Text(L10n.Tvshow.Detail.similarHeadline).font(.title3)
            ScrollView(.horizontal) {
                LazyHGrid(
                    rows: [
                        GridItem(.fixed(PosterSize.medium.height)),
                        GridItem(.fixed(PosterSize.medium.height)),
                    ],
                    spacing: 16
                ) {
                    ForEach(displayedItems) { item in
                        SimilarPosterCellView(entity: item)
                    }
                }
                .redacted(reason: isPlaceholder ? .placeholder : [])
                .allowsHitTesting(!isPlaceholder)
            }
        }
        .task {
            await viewModel.load()
            dump(viewModel)
        }
        .debugPrintChanges()
    }
}

struct SimilarPosterCellView: View {
    let entity: SimilarTVShowEntity
    var body: some View {
        RemoteTMDBImage(
            posterPath: entity.tmdbImagePath,
            imageSize: .posterMedium
        )
        .frame(width: PosterSize.medium.width, height: PosterSize.medium.height)
    }
}

#if DEBUG
import TMDB_Shared_Backend
@available(iOS 17, *)
#Preview {
    SimilarTVSection(viewModel: SimilarTVViewModel(apiService: TMDBAPIService(apiKey: debugTMDBAPIKey), tvShowId: 138502))
}
#endif
