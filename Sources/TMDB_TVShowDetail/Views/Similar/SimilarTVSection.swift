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
                    spacing: 8
                ) {
                    ForEach(Array(displayedItems.enumerated()), id: \.element.id) { index, item in
                        SimilarPosterCellView(entity: item) {
                            Task {
                                await viewModel.toggleFavorite(at: index)
                            }
                        }
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
    var onBookmarkTap: (()->Void)? = nil
    var body: some View {
        RemoteTMDBImage(
            posterPath: entity.tmdbImagePath,
            imageSize: .posterMedium
        )
        .frame(width: PosterSize.medium.width, height: PosterSize.medium.height)
        .overlay(alignment: .topTrailing) {
            Image(systemName: entity.bookmarked ? "bookmark.fill" : "plus")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(entity.bookmarked ? .black : .white)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 26, height: 32)
                .background(
                    entity.bookmarked ? AnyShapeStyle(.yellow.gradient) : AnyShapeStyle(.ultraThinMaterial),
                    in: .rect(topLeadingRadius: 4, bottomLeadingRadius: 8, bottomTrailingRadius: 8, topTrailingRadius: 10)
                )
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 8, bottomTrailingRadius: 8, topTrailingRadius: 10)
                        .strokeBorder(.white.opacity(0.25), lineWidth: 0.75)
                )
                .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
                .padding(.trailing, 6)
                .contentShape(Rectangle())
                .sensoryFeedback(.impact(weight: .light), trigger: entity.bookmarked)
                .onTapGesture {
                    onBookmarkTap?()
                }
        }
    }
}

#if DEBUG
#Preview("Poster cell") {
    TMDBTVShowDetailPreviewCatalog.similarPosterCell.view
}

#Preview {
    TMDBTVShowDetailPreviewCatalog.similarSection.view
}
#endif
