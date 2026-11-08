import Shared_UI_Support
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

/// A regular-width feed (iPad) in as many columns of tiles as fit. A full-width row stretched
/// across an iPad leaves its text a long way from its poster and most of the screen empty, and
/// a 1–3 column card grid turns every poster into a billboard; tiles keep their shape instead.
@available(iOS 16, *)
struct FeedTileGrid<Route: Hashable, Tile: View>: View {
    let items: [FeedItem<Route>]
    /// Narrowest a tile gets before the grid drops a column.
    let minimumTileWidth: CGFloat
    /// Pagination hook — called with each item as it scrolls into view.
    let onItemAppear: (FeedItem<Route>) -> Void
    @ViewBuilder let tile: (FeedItem<Route>) -> Tile

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: minimumTileWidth), spacing: 16, alignment: .top)],
                spacing: 16
            ) {
                ForEach(items) { item in
                    tile(item)
                        .onAppear { onItemAppear(item) }
                }
            }
            .padding(16)
        }
    }
}

@available(iOS 16, *)
extension FeedContentDesign {
    /// How narrow one tile of this design gets on a regular-width feed before the grid drops a
    /// column — 2–4 columns across iPad sizes and orientations. `nil` for the poster grid,
    /// which already fills any width with its own small cells.
    var regularWidthTileMinimum: CGFloat? {
        switch self {
        case .list: return 340 // room for the overview beside the poster
        case .compactRows: return 280
        case .paletteCards: return 220
        case .grid: return nil
        }
    }
}

/// One row of a row design as a card. Not inside a `List(selection:)`, so it drives the
/// selection itself like the poster grid cells do.
@available(iOS 16, *)
struct FeedTile<Route: Hashable>: View {
    let item: FeedItem<Route>
    let style: FeedContentDesign

    var body: some View {
        FeedRowLink(route: item.route, drivesSelectionDirectly: true) {
            Group {
                if style == .compactRows {
                    FeedCompactRowContent(entity: item.entity)
                } else {
                    FeedListTileContent(entity: item.entity)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Translucent, so a split view's selection highlight still shows through.
            .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 12))
        }
        // A push tile is a NavigationLink; outside a List its label picks up the accent tint.
        .buttonStyle(.plain)
        .accessibilityIdentifier(item.accessibilityIdentifier)
    }
}

/// `MovieRow`'s content — poster, title, rating, date, overview — at a fixed height, so every
/// tile in a grid row is as tall as its neighbours.
@available(iOS 16, *)
struct FeedListTileContent: View {
    let entity: MovieRowEntity

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RemoteTMDBImage(posterPath: entity.posterPath ?? "", imageSize: .posterLarge)
                .frame(width: PosterSize.medium.width, height: PosterSize.medium.height)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .redacted(if: entity.posterPath == nil)

            VStack(alignment: .leading, spacing: 6) {
                Text(entity.title)
                    .font(.headline)
                    .foregroundStyle(Color.steamGold)
                    .lineLimit(2)
                    .layoutPriority(1)

                HStack(spacing: 8) {
                    PopularityBadge(score: Int(entity.voteAverage * 10))
                    // TV shows carry no date; showing today instead would be wrong.
                    if let releaseDate = entity.releaseDate {
                        Text(releaseDate, format: .dateTime.year().month().day())
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                }

                Text(entity.overview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer(minLength: 0)
        }
        .frame(height: PosterSize.medium.height, alignment: .top)
    }
}

#if DEBUG
#Preview("Tiles") {
    NavigationStack {
        VStack(spacing: 16) {
            FeedTile(item: Movie.previewMovies[0].feedItem(route: 1), style: .list)
            FeedTile(item: TVShow.examples[0].feedItem(route: 2), style: .list)
            FeedTile(item: Movie.previewMovies[1].feedItem(route: 3), style: .compactRows)
        }
        .padding()
        .frame(maxWidth: 380)
    }
}

#Preview("Tile grid", traits: .landscapeLeft) {
    NavigationStack {
        FeedTileGrid(
            items: Movie.previewMovies.map { $0.feedItem(route: $0.id) },
            minimumTileWidth: 340,
            onItemAppear: { _ in },
            tile: { FeedTile(item: $0, style: .list) }
        )
    }
}
#endif
