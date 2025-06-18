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
        HStack(spacing: 4) {
            Image(systemName: filterType.iconName)
                .font(.caption)

            Text(displayText)
                .font(.caption)
                .fontWeight(.medium)

            if isActive {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 1)
        )
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
    let onFilterTap: (FilterType) -> Void

    public init(filters: Binding<SearchFilters>, onFilterTap: @escaping (FilterType) -> Void) {
        _filters = filters
        self.onFilterTap = onFilterTap
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FilterType.allCases) { filterType in
                    FilterChip(
                        filterType: filterType,
                        isActive: isFilterActive(filterType),
                        value: getFilterValue(filterType),
                        onTap: { onFilterTap(filterType) },
                        onRemove: { removeFilter(filterType) }
                    )
                }

                if filters.hasActiveFilters {
                    Button(L10n.filterClearAll) {
                        filters.clearAll()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
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