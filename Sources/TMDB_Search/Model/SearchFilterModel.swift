import Foundation

public struct SearchFilters: Equatable, Hashable {
    public var includeAdult: Bool
    public var language: String?
    public var primaryReleaseYear: String?
    public var firstAirDateYear: String?
    public var region: String?
    public var year: String?

    public init(
        includeAdult: Bool = false,
        language: String? = nil,
        primaryReleaseYear: String? = nil,
        firstAirDateYear: String? = nil,
        region: String? = nil,
        year: String? = nil
    ) {
        self.includeAdult = includeAdult
        self.language = language
        self.primaryReleaseYear = primaryReleaseYear
        self.firstAirDateYear = firstAirDateYear
        self.region = region
        self.year = year
    }

    public var hasActiveFilters: Bool {
        FilterType.allCases.contains(where: isActive)
    }

    public mutating func clearAll() {
        self = SearchFilters()
    }

    public func isActive(_ filter: FilterType) -> Bool {
        guard let keyPath = filter.valueKeyPath else { return includeAdult }
        return self[keyPath: keyPath] != nil
    }

    public mutating func reset(_ filter: FilterType) {
        guard let keyPath = filter.valueKeyPath else {
            includeAdult = false
            return
        }
        self[keyPath: keyPath] = nil
    }

    /// What an active chip shows after its name: a year as is, a language or country by its
    /// name, the adult toggle as "On".
    public func displayValue(for filter: FilterType) -> String? {
        guard isActive(filter) else { return nil }
        guard let keyPath = filter.valueKeyPath else { return L10n.filterValueOn }
        return self[keyPath: keyPath].map(filter.title(for:))
    }

    /// The subset of these filters a given scope's endpoint actually accepts.
    ///
    /// Filters outlive a scope change on purpose — flipping from Movies to TV and back should
    /// not lose the year you picked — so the request has to drop what the new endpoint cannot
    /// use rather than the model forgetting it.
    public func narrowed(to scope: SearchScope) -> SearchFilters {
        var narrowed = self
        for filter in FilterType.allCases where !scope.supportedFilters.contains(filter) {
            narrowed.reset(filter)
        }
        return narrowed
    }
}

/// One chip per query parameter the TMDB search endpoints take besides `query` and `page`.
public enum FilterType: String, CaseIterable, Identifiable {
    case includeAdult = "include_adult"
    case language = "language"
    case primaryReleaseYear = "primary_release_year"
    case firstAirDateYear = "first_air_date_year"
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
        case .firstAirDateYear:
            return L10n.filterFirstAirDateYear
        case .region:
            return L10n.filterRegion
        case .year:
            return L10n.filterYear
        }
    }

    /// What the parameter does, as the picker's headline.
    public var summary: String {
        switch self {
        case .includeAdult:
            return L10n.filterIncludeAdultDescription
        case .language:
            return L10n.filterLanguageDescription
        case .primaryReleaseYear:
            return L10n.filterPrimaryReleaseYearDescription
        case .firstAirDateYear:
            return L10n.filterFirstAirDateYearDescription
        case .region:
            return L10n.filterRegionDescription
        case .year:
            return L10n.filterYearDescription
        }
    }

    public var iconName: String {
        switch self {
        case .includeAdult:
            return "person.2"
        case .language:
            return "globe"
        case .primaryReleaseYear, .firstAirDateYear:
            return "calendar"
        case .region:
            return "map"
        case .year:
            return "calendar.badge.clock"
        }
    }

    /// Where a picker filter keeps its value; `nil` for the include-adult toggle.
    var valueKeyPath: WritableKeyPath<SearchFilters, String?>? {
        switch self {
        case .includeAdult: return nil
        case .language: return \.language
        case .primaryReleaseYear: return \.primaryReleaseYear
        case .firstAirDateYear: return \.firstAirDateYear
        case .region: return \.region
        case .year: return \.year
        }
    }

    /// The values the picker offers, as TMDB spells them; empty for the include-adult toggle.
    public var options: [String] {
        switch self {
        case .includeAdult:
            return []
        case .language:
            return ["en-US", "en-GB", "es", "fr", "de", "it", "pt", "ru", "ja", "ko", "zh"]
        case .region:
            return ["US", "GB", "CA", "AU", "DE", "FR", "ES", "IT", "JP", "KR", "CN"]
        case .primaryReleaseYear, .firstAirDateYear, .year:
            // Newest first, a little past this year for announced titles.
            let thisYear = Calendar.current.component(.year, from: Date())
            return (1900...thisYear + 2).reversed().map(String.init)
        }
    }

    /// The picker row that leaves the filter off.
    public var anyValueTitle: String {
        switch self {
        case .language: return L10n.filterAnyLanguage
        case .region: return L10n.filterAnyRegion
        case .includeAdult, .primaryReleaseYear, .firstAirDateYear, .year: return L10n.filterAnyYear
        }
    }

    /// A value as the user reads it: languages and countries named in their own language.
    public func title(for value: String) -> String {
        switch self {
        case .language: return Locale.current.localizedString(forIdentifier: value) ?? value
        case .region: return Locale.current.localizedString(forRegionCode: value) ?? value
        case .includeAdult, .primaryReleaseYear, .firstAirDateYear, .year: return value
        }
    }
}
