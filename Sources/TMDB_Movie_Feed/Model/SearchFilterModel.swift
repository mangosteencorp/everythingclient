import Foundation

public struct SearchFilters: Equatable, Hashable {
    public var includeAdult: Bool
    public var language: String?
    public var primaryReleaseYear: String?
    public var region: String?
    public var year: String?

    public init(
        includeAdult: Bool = false,
        language: String? = nil,
        primaryReleaseYear: String? = nil,
        region: String? = nil,
        year: String? = nil
    ) {
        self.includeAdult = includeAdult
        self.language = language
        self.primaryReleaseYear = primaryReleaseYear
        self.region = region
        self.year = year
    }

    public var hasActiveFilters: Bool {
        return includeAdult || language != nil || primaryReleaseYear != nil || region != nil || year != nil
    }

    public mutating func clearAll() {
        includeAdult = false
        language = nil
        primaryReleaseYear = nil
        region = nil
        year = nil
    }
}

public enum FilterType: String, CaseIterable, Identifiable {
    case includeAdult = "include_adult"
    case language = "language"
    case primaryReleaseYear = "primary_release_year"
    case region = "region"
    case year = "year"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .includeAdult:
            return L10n.filterIncludeAdult
        case .language:
            return L10n.filterLanguage
        case .primaryReleaseYear:
            return L10n.filterPrimaryReleaseYear
        case .region:
            return L10n.filterRegion
        case .year:
            return L10n.filterYear
        }
    }

    public var iconName: String {
        switch self {
        case .includeAdult:
            return "person.2"
        case .language:
            return "globe"
        case .primaryReleaseYear:
            return "calendar"
        case .region:
            return "map"
        case .year:
            return "calendar.badge.clock"
        }
    }
}