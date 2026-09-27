import SwiftUI
import TMDB_Shared_UI

/// What the page shows before anything is typed: your recent searches, then today's trending
/// titles. With neither, a one-line prompt instead of a blank page.
@available(iOS 16, *)
struct SearchIdleView<Route: Hashable>: View {
    let recents: [String]
    let trending: [SearchResultItem]
    let routeBuilder: (SearchResultItem) -> Route?
    let onSelectRecent: (String) -> Void
    let onRemoveRecent: (String) -> Void
    let onClearRecents: () -> Void

    var body: some View {
        Group {
            if recents.isEmpty, trending.isEmpty {
                FeedPlaceholderView(systemImage: "magnifyingglass", title: L10n.searchIdlePrompt)
            } else {
                List {
                    if !recents.isEmpty {
                        Section {
                            ForEach(recents, id: \.self) { recent in
                                RecentSearchRow(query: recent) { onSelectRecent(recent) }
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            onRemoveRecent(recent)
                                        } label: {
                                            Label(L10n.searchRecentsRemove, systemImage: "trash")
                                        }
                                    }
                            }
                        } header: {
                            SearchSectionHeader(title: L10n.searchRecentsTitle) {
                                Button(L10n.searchRecentsClear, action: onClearRecents)
                                    .font(.subheadline)
                                    .accessibilityIdentifier("search_recents_clear")
                            }
                        }
                        .headerProminence(.increased)
                    }

                    if !trending.isEmpty {
                        Section {
                            TrendingCarousel(items: trending, routeBuilder: routeBuilder)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                        } header: {
                            SearchSectionHeader(title: L10n.searchTrendingTitle) { EmptyView() }
                        }
                        .headerProminence(.increased)
                    }
                }
                .listStyle(.plain)
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .accessibilityIdentifier("search_idle")
    }
}

/// A section title with an optional trailing control; the section's `.increased` prominence
/// makes it the large bold header of the Music and TV search pages.
@available(iOS 16, *)
struct SearchSectionHeader<Accessory: View>: View {
    let title: String
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            accessory()
        }
        .textCase(nil)
    }
}

/// A past query; tapping it searches again.
@available(iOS 16, *)
struct RecentSearchRow: View {
    let query: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.secondary)
                Text(query)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "arrow.up.left")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(query)
        .accessibilityIdentifier("search_recent")
    }
}

/// Trending titles as a row of posters.
@available(iOS 16, *)
struct TrendingCarousel<Route: Hashable>: View {
    let items: [SearchResultItem]
    let routeBuilder: (SearchResultItem) -> Route?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(items) { item in
                    if let route = routeBuilder(item) {
                        NavigationLink(value: route) {
                            SearchPosterCard(item: item)
                        }
                        .buttonStyle(.plain)
                    } else {
                        SearchPosterCard(item: item)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .accessibilityIdentifier("search_trending")
    }
}

/// A poster with its title and year underneath — or a round portrait, for people.
@available(iOS 16, *)
struct SearchPosterCard: View {
    let item: SearchResultItem

    @ScaledMetric(relativeTo: .body) private var width: CGFloat = 110

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SearchArtwork(item: item, width: width)
                // Portraits sit in a poster-sized slot so the titles along the row line up.
                .frame(height: width * 1.5)

            Text(item.title)
                .font(.footnote.weight(.semibold))
                .lineLimit(2)

            Text(item.year ?? item.kind.title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: width)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([item.title, item.kind.title, item.year].compactMap { $0 }.joined(separator: ", "))
    }
}

#if DEBUG
@available(iOS 16, *)
#Preview("Idle — recents and trending") {
    NavigationStack {
        SearchIdleView(
            recents: ["Dune", "Christopher Nolan", "Breaking Bad"],
            trending: StubSearchService.items(for: .multi, query: "trending", page: 1, count: 8),
            routeBuilder: { _ in 1 },
            onSelectRecent: { _ in },
            onRemoveRecent: { _ in },
            onClearRecents: {}
        )
    }
}

@available(iOS 16, *)
#Preview("Idle — nothing yet") {
    SearchIdleView<Int>(
        recents: [],
        trending: [],
        routeBuilder: { _ in nil },
        onSelectRecent: { _ in },
        onRemoveRecent: { _ in },
        onClearRecents: {}
    )
}

@available(iOS 16, *)
#Preview("Recent search row") {
    List {
        RecentSearchRow(query: "The Lord of the Rings") {}
    }
    .listStyle(.plain)
}

@available(iOS 16, *)
#Preview("Section header") {
    List {
        Section {
            Text("Dune")
        } header: {
            SearchSectionHeader(title: "Recent Searches") {
                Button("Clear") {}
            }
        }
        .headerProminence(.increased)
    }
    .listStyle(.plain)
}

@available(iOS 16, *)
#Preview("Poster cards") {
    HStack(alignment: .top) {
        ForEach(StubSearchService.items(for: .multi, query: "super", page: 1, count: 3)) { item in
            SearchPosterCard(item: item)
        }
    }
    .padding()
}
#endif
