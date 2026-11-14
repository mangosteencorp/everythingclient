import CoreFeatures
import Shared_UI_Support
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

/// One row's worth of data, normalised so movies and TV shows share a single renderer.
struct FeedItem<Route: Hashable>: Identifiable {
    let id: Int
    let entity: MovieRowEntity
    let route: Route
    let accessibilityIdentifier: String
}

/// Renders a loaded feed in whatever layout `FeedContentDesign` currently asks for.
///
/// Every feed in the module goes through here, so a new layout appears in the movie feeds,
/// the TV feeds and both search result lists at once.
@available(iOS 16, *)
struct FeedItemsView<Route: Hashable>: View {
    let items: [FeedItem<Route>]
    let accessibilityIdentifier: String
    /// Pagination hook — called with each item as it scrolls into view.
    let onItemAppear: (FeedItem<Route>) -> Void

    @DesignStyle private var design: FeedContentDesign
    @Environment(\.feedNavigationMode) private var navigationMode
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        // Wide feeds (iPad, regular width) lay their tiles out in as many columns as fit. A split
        // view's sidebar column is compact, so it keeps its selectable list.
        if horizontalSizeClass == .regular, let minimumTileWidth = design.regularWidthTileMinimum {
            FeedTileGrid(items: items, minimumTileWidth: minimumTileWidth, onItemAppear: onItemAppear) { item in
                if design == .paletteCards {
                    FeedPaletteCell(item: item)
                } else {
                    FeedTile(item: item, style: design)
                }
            }
            .accessibilityIdentifier(accessibilityIdentifier)
        } else {
            singleLayoutBody
        }
    }

    /// Every design at compact width, and the poster grid, which fills any width as it is.
    @ViewBuilder
    private var singleLayoutBody: some View {
        switch design {
        case .list:
            feedList(style: .list)
                .accessibilityIdentifier(accessibilityIdentifier)
        case .compactRows:
            feedList(style: .compactRows)
                .listStyle(.plain)
                .accessibilityIdentifier(accessibilityIdentifier)
        case .grid:
            ScrollView {
                LazyVGrid(columns: Self.gridColumns, spacing: 16) {
                    ForEach(items) { item in
                        FeedGridCell(item: item)
                            .onAppear { onItemAppear(item) }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .accessibilityIdentifier(accessibilityIdentifier)
        case .paletteCards:
            AdaptiveColumnGrid(items: items) { item in
                FeedPaletteCell(item: item)
                    .onAppear { onItemAppear(item) }
            }
            .accessibilityIdentifier(accessibilityIdentifier)
        }
    }

    /// `List(selection:)` when the host wants selection, a plain `List` otherwise — the two
    /// initialisers are not interchangeable, so the branch has to happen here.
    @ViewBuilder
    private func feedList(style: FeedContentDesign) -> some View {
        if case let .select(selection) = navigationMode {
            List(selection: selection) {
                ForEach(items) { item in
                    FeedItemRow(item: item, style: style, onAppear: { onItemAppear(item) })
                        .tag(AnyHashable(item.route))
                }
            }
        } else {
            List(items) { item in
                FeedItemRow(item: item, style: style, onAppear: { onItemAppear(item) })
            }
        }
    }

    private static var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: PosterSize.grid.width), spacing: 12, alignment: .top)]
    }
}

@available(iOS 16, *)
struct FeedItemRow<Route: Hashable>: View {
    let item: FeedItem<Route>
    let style: FeedContentDesign
    let onAppear: () -> Void

    var body: some View {
        FeedRowLink(route: item.route) {
            if style == .compactRows {
                FeedCompactRowContent(entity: item.entity)
            } else {
                MovieRow(movie: item.entity)
            }
        }
        .accessibilityIdentifier(item.accessibilityIdentifier)
        .onAppear(perform: onAppear)
    }
}

/// Shared by the compact row and its regular-width tile.
@available(iOS 16, *)
struct FeedCompactRowContent: View {
    let entity: MovieRowEntity

    var body: some View {
        HStack(spacing: 12) {
            RemoteTMDBImage(posterPath: entity.posterPath ?? "", imageSize: .posterSmall)
                .frame(width: PosterSize.thumbnail.width, height: PosterSize.thumbnail.height)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .redacted(if: entity.posterPath == nil)

            Text(entity.title)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            PopularityBadge(score: Int(entity.voteAverage * 10))
        }
        .padding(.vertical, 2)
    }
}

@available(iOS 16, *)
private struct FeedGridCell<Route: Hashable>: View {
    let item: FeedItem<Route>

    var body: some View {
        FeedRowLink(route: item.route, drivesSelectionDirectly: true) {
            VStack(alignment: .leading, spacing: 6) {
                RemoteTMDBImage(posterPath: item.entity.posterPath ?? "", imageSize: .posterLarge)
                    .frame(width: PosterSize.grid.width, height: PosterSize.grid.height)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .redacted(if: item.entity.posterPath == nil)

                Text(item.entity.title)
                    .font(.caption)
                    .lineLimit(2, reservesSpace: true)
                    .frame(width: PosterSize.grid.width, alignment: .leading)
            }
        }
        // A push cell is a NavigationLink; outside a List its label picks up the accent tint.
        .buttonStyle(.plain)
        .accessibilityIdentifier(item.accessibilityIdentifier)
    }
}

/// The `MovieItemCell` palette trick in SwiftUI: the poster paints the card, and the text
/// picks whichever of black or white survives on top of it.
@available(iOS 16, *)
private struct FeedPaletteCell<Route: Hashable>: View {
    let item: FeedItem<Route>

    var body: some View {
        FeedRowLink(route: item.route, drivesSelectionDirectly: true) {
            PaletteCard(imageURL: posterURL) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.entity.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text(String(format: "%.1f", item.entity.voteAverage))
                            .font(.caption)
                        Spacer(minLength: 0)
                    }
                    .opacity(0.85)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(item.accessibilityIdentifier)
    }

    private var posterURL: URL? {
        guard let posterPath = item.entity.posterPath else { return nil }
        return TMDBImageSize.posterMedium.buildImageUrl(path: posterPath)
    }
}

#if DEBUG
#Preview("List") {
    FeedItemsPreview(design: .list)
}

#Preview("Compact rows") {
    FeedItemsPreview(design: .compactRows)
}

#Preview("Grid") {
    FeedItemsPreview(design: .grid)
}

#Preview("Palette cards") {
    FeedItemsPreview(design: .paletteCards)
}

#Preview("List, regular width", traits: .landscapeLeft) {
    FeedItemsPreview(design: .list, sizeClass: .regular)
}

#Preview("Compact rows, regular width", traits: .landscapeLeft) {
    FeedItemsPreview(design: .compactRows, sizeClass: .regular)
}

#Preview("Grid, regular width", traits: .landscapeLeft) {
    FeedItemsPreview(design: .grid, sizeClass: .regular)
}

#Preview("Palette cards, regular width", traits: .landscapeLeft) {
    FeedItemsPreview(design: .paletteCards, sizeClass: .regular)
}

#Preview("Rows") {
    NavigationStack {
        List {
            FeedItemRow(item: Movie.previewMovies[0].feedItem(route: 1), style: .list, onAppear: {})
            FeedItemRow(item: Movie.previewMovies[1].feedItem(route: 2), style: .compactRows, onAppear: {})
        }
    }
}

/// Each preview pins its layout, leaving the shared coordinator alone; the private cells are
/// only reachable through their layout.
private struct FeedItemsPreview: View {
    let design: FeedContentDesign
    /// `.regular` stands in for an iPad-width feed on any canvas device; `nil` keeps the canvas's.
    var sizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) private var canvasSizeClass

    var body: some View {
        NavigationStack {
            FeedItemsView(
                items: Movie.previewMovies.map { $0.feedItem(route: $0.id) },
                accessibilityIdentifier: "preview",
                onItemAppear: { _ in }
            )
        }
        .designStyle(design)
        .environment(\.horizontalSizeClass, sizeClass ?? canvasSizeClass)
    }
}
#endif
