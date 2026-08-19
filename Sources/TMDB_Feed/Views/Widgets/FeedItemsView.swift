import CoreFeatures
import Shared_UI_Support
import SwiftUI
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

    var body: some View {
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
        [GridItem(.adaptive(minimum: PosterSize.grid.width), spacing: 12)]
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

@available(iOS 16, *)
private struct FeedCompactRowContent: View {
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
                    .lineLimit(2)
                    .frame(width: PosterSize.grid.width, alignment: .leading)
            }
        }
        // A push cell is a NavigationLink; outside a List its label picks up the accent tint.
        .buttonStyle(.plain)
        .accessibilityIdentifier(item.accessibilityIdentifier)
    }
}
