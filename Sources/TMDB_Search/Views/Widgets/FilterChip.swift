import SwiftUI

@available(iOS 16.0, *)
public struct FilterChip: View {
    let filterType: FilterType
    let isActive: Bool
    let value: String?
    let onTap: () -> Void
    let onRemove: () -> Void

    public init(
        filterType: FilterType,
        isActive: Bool,
        value: String? = nil,
        onTap: @escaping () -> Void,
        onRemove: @escaping () -> Void
    ) {
        self.filterType = filterType
        self.isActive = isActive
        self.value = value
        self.onTap = onTap
        self.onRemove = onRemove
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: filterType.iconName)

            Text(displayText)
                .fontWeight(.medium)
                .lineLimit(1)

            if isActive {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            } else {
                // Tapping opens a picker sheet; the chevron says so.
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .font(.footnote)
        .foregroundStyle(isActive ? Color.accentColor : Color.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(isActive ? Color.accentColor.opacity(0.15) : Color(.secondarySystemFill))
        )
        .overlay(
            Capsule()
                .strokeBorder(isActive ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
        )
        .contentShape(Capsule())
        .onTapGesture {
            onTap()
        }
    }

    private var displayText: String {
        if isActive, let value = value {
            return "\(filterType.displayName): \(value)"
        } else {
            return filterType.displayName
        }
    }
}

@available(iOS 16.0, *)
public struct FilterChipsView: View {
    @Binding var filters: SearchFilters
    /// Which chips to offer. Search narrows this per scope, because TMDB accepts a different
    /// parameter set per endpoint; the feed passes every type.
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(types) { filterType in
                    FilterChip(
                        filterType: filterType,
                        isActive: isFilterActive(filterType),
                        value: getFilterValue(filterType),
                        onTap: { onFilterTap(filterType) },
                        onRemove: { removeFilter(filterType) }
                    )
                }

                if hasActiveVisibleFilters {
                    Button(L10n.filterClearAll) {
                        filters.clearAll()
                    }
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.red.opacity(0.1)))
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 6)
    }

    /// "Clear all" should not appear because of a filter this scope is not even showing.
    private var hasActiveVisibleFilters: Bool {
        types.contains(where: isFilterActive)
    }

    private func isFilterActive(_ filterType: FilterType) -> Bool {
        switch filterType {
        case .includeAdult:
            return filters.includeAdult
        case .language:
            return filters.language != nil
        case .primaryReleaseYear:
            return filters.primaryReleaseYear != nil
        case .region:
            return filters.region != nil
        case .year:
            return filters.year != nil
        }
    }

    private func getFilterValue(_ filterType: FilterType) -> String? {
        switch filterType {
        case .includeAdult:
            return filters.includeAdult ? "Yes" : nil
        case .language:
            return filters.language
        case .primaryReleaseYear:
            return filters.primaryReleaseYear
        case .region:
            return filters.region
        case .year:
            return filters.year
        }
    }

    private func removeFilter(_ filterType: FilterType) {
        switch filterType {
        case .includeAdult:
            filters.includeAdult = false
        case .language:
            filters.language = nil
        case .primaryReleaseYear:
            filters.primaryReleaseYear = nil
        case .region:
            filters.region = nil
        case .year:
            filters.year = nil
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
#Preview {
    VStack {
        FilterChipsView(
            filters: .constant(SearchFilters(includeAdult: true, language: "en-US", primaryReleaseYear: "2024"))
        ) { filterType in
            print("Tapped: \(filterType.displayName)")
        }

        FilterChipsView(
            filters: .constant(SearchFilters())
        ) { filterType in
            print("Tapped: \(filterType.displayName)")
        }
    }
}
#endif