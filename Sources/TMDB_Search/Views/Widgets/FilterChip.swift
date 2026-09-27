import SwiftUI

/// One filter as a capsule: its name, and its value once set.
///
/// Tapping it opens its picker; an active chip also gets a remove button, as a separate target
/// so VoiceOver and UI tests can reach both.
@available(iOS 16.0, *)
public struct FilterChip: View {
    let filterType: FilterType
    /// The value as the user reads it — "2021", "French" — or `nil` while the filter is off.
    let value: String?
    let onTap: () -> Void
    let onRemove: () -> Void

    public init(
        filterType: FilterType,
        value: String? = nil,
        onTap: @escaping () -> Void,
        onRemove: @escaping () -> Void
    ) {
        self.filterType = filterType
        self.value = value
        self.onTap = onTap
        self.onRemove = onRemove
    }

    private var isActive: Bool { value != nil }

    public var body: some View {
        HStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 6) {
                    Image(systemName: filterType.iconName)

                    Text(title)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    if !isActive {
                        // Tapping opens a picker sheet; the chevron says so.
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.leading, 12)
                .padding(.trailing, isActive ? 4 : 12)
                .padding(.vertical, 7)
                .contentShape(Rectangle())
            }
            .accessibilityLabel(title)
            .accessibilityAddTraits(isActive ? .isSelected : [])
            .accessibilityIdentifier("search_filter_chip_\(filterType.id)")

            if isActive {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .padding(.leading, 2)
                        .padding(.trailing, 10)
                        .padding(.vertical, 7)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(L10n.filterRemove(filterType.displayName))
                .accessibilityIdentifier("search_filter_remove_\(filterType.id)")
            }
        }
        .buttonStyle(.plain)
        .font(.footnote)
        .foregroundStyle(isActive ? Color.accentColor : Color.primary)
        .background(
            Capsule()
                .fill(isActive ? Color.accentColor.opacity(0.15) : Color(.secondarySystemFill))
        )
        .overlay(
            Capsule()
                .strokeBorder(isActive ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
        )
    }

    private var title: String {
        guard let value else { return filterType.displayName }
        return L10n.filterChipValue(filterType.displayName, value)
    }
}

/// The scrolling row of chips under the scope bar.
@available(iOS 16.0, *)
public struct FilterChipsView: View {
    @Binding var filters: SearchFilters
    /// Which chips to offer. Search narrows this per scope, because TMDB accepts a different
    /// parameter set per endpoint.
    let types: [FilterType]
    let onFilterTap: (FilterType) -> Void

    public init(
        filters: Binding<SearchFilters>,
        types: [FilterType] = FilterType.allCases,
        onFilterTap: @escaping (FilterType) -> Void
    ) {
        _filters = filters
        self.types = types
        self.onFilterTap = onFilterTap
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Pinned outside the scroll, so it stays on screen however far the chips scroll.
            if hasActiveVisibleFilters {
                Button(L10n.filterClearAll) {
                    filters.clearAll()
                }
                .font(.footnote.weight(.medium))
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color.red.opacity(0.1)))
                .padding(.leading, 16)
                .accessibilityIdentifier("search_filter_clear_all")
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(types) { filterType in
                            FilterChip(
                                filterType: filterType,
                                value: filters.displayValue(for: filterType),
                                onTap: { onFilterTap(filterType) },
                                onRemove: { filters.reset(filterType) }
                            )
                            .id(filterType)
                        }
                    }
                    .padding(.leading, hasActiveVisibleFilters ? fadeWidth : 16)
                    .padding(.trailing, 16)
                }
                // Chips scrolled under "Clear All" fade out rather than stop dead against it.
                .mask {
                    HStack(spacing: 0) {
                        LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                            .frame(width: hasActiveVisibleFilters ? fadeWidth : 0)
                        Color.black
                    }
                }
                // A chip just set grows, and "Clear All" appearing narrows the row: bring it
                // back into view rather than leave its value cut off at the edge.
                .onChange(of: filters) { old, new in
                    guard let changed = types.first(where: {
                        new.isActive($0) && old.displayValue(for: $0) != new.displayValue(for: $0)
                    }) else { return }
                    withAnimation { proxy.scrollTo(changed) }
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("search_filter_bar")
    }

    private let fadeWidth: CGFloat = 12

    /// "Clear all" should not appear because of a filter this scope is not even showing.
    private var hasActiveVisibleFilters: Bool {
        types.contains(where: filters.isActive)
    }
}

#if DEBUG
@available(iOS 16.0, *)
#Preview("Chip — every filter, off and on") {
    let active = SearchFilters(
        includeAdult: true,
        language: "fr",
        primaryReleaseYear: "2021",
        firstAirDateYear: "2019",
        region: "JP",
        year: "1984"
    )
    VStack(alignment: .leading, spacing: 12) {
        ForEach(FilterType.allCases) { filterType in
            HStack {
                FilterChip(filterType: filterType, onTap: {}, onRemove: {})
                FilterChip(filterType: filterType, value: active.displayValue(for: filterType), onTap: {}, onRemove: {})
            }
        }
    }
    .padding()
}

@available(iOS 16.0, *)
#Preview("Chip row — none active") {
    FilterChipsView(filters: .constant(SearchFilters()), types: SearchScope.movies.supportedFilters) { _ in }
}

@available(iOS 16.0, *)
#Preview("Chip row — some active") {
    @Previewable @State var filters = SearchFilters(language: "en-US", primaryReleaseYear: "2024")
    FilterChipsView(filters: $filters, types: SearchScope.movies.supportedFilters) { _ in }
}

@available(iOS 16.0, *)
#Preview("Chip row — each scope") {
    let filters = SearchFilters(firstAirDateYear: "2019", region: "GB")
    VStack(alignment: .leading, spacing: 4) {
        ForEach(SearchScope.allCases.filter { !$0.supportedFilters.isEmpty }) { scope in
            Text(scope.title)
                .font(.caption)
                .padding(.horizontal)
            FilterChipsView(filters: .constant(filters), types: scope.supportedFilters) { _ in }
        }
    }
}
#endif
