// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  /// Localizable.strings
  ///   everythingclient
  /// 
  ///   Created by Quang on 2024-09-30.
  public static let feedSearch = L10n.tr("Localizable", "feed_search", fallback: "Search")
  /// Any Language
  public static let filterAnyLanguage = L10n.tr("Localizable", "filter_any_language", fallback: "Any Language")
  /// Any Region
  public static let filterAnyRegion = L10n.tr("Localizable", "filter_any_region", fallback: "Any Region")
  /// Cancel
  public static let filterCancel = L10n.tr("Localizable", "filter_cancel", fallback: "Cancel")
  /// Clear
  public static let filterClear = L10n.tr("Localizable", "filter_clear", fallback: "Clear")
  /// Clear All
  public static let filterClearAll = L10n.tr("Localizable", "filter_clear_all", fallback: "Clear All")
  /// Done
  public static let filterDone = L10n.tr("Localizable", "filter_done", fallback: "Done")
  /// Enter year (e.g., 2024)
  public static let filterEnterYear = L10n.tr("Localizable", "filter_enter_year", fallback: "Enter year (e.g., 2024)")
  /// Include Adult
  public static let filterIncludeAdult = L10n.tr("Localizable", "filter_include_adult", fallback: "Include Adult")
  /// Include adult content in search results
  public static let filterIncludeAdultDescription = L10n.tr("Localizable", "filter_include_adult_description", fallback: "Include adult content in search results")
  /// Language
  public static let filterLanguage = L10n.tr("Localizable", "filter_language", fallback: "Language")
  /// Select language for search results
  public static let filterLanguageDescription = L10n.tr("Localizable", "filter_language_description", fallback: "Select language for search results")
  /// Release Year
  public static let filterPrimaryReleaseYear = L10n.tr("Localizable", "filter_primary_release_year", fallback: "Release Year")
  /// Region
  public static let filterRegion = L10n.tr("Localizable", "filter_region", fallback: "Region")
  /// Select region for search results
  public static let filterRegionDescription = L10n.tr("Localizable", "filter_region_description", fallback: "Select region for search results")
  /// Year
  public static let filterYear = L10n.tr("Localizable", "filter_year", fallback: "Year")
  /// Enter a 4-digit year (e.g., 2024)
  public static let filterYearDescription = L10n.tr("Localizable", "filter_year_description", fallback: "Enter a 4-digit year (e.g., 2024)")
  /// Clear Search
  public static let searchEmptyClear = L10n.tr("Localizable", "search_empty_clear", fallback: "Clear Search")
  /// Check the spelling, or try another category.
  public static let searchEmptyMessage = L10n.tr("Localizable", "search_empty_message", fallback: "Check the spelling, or try another category.")
  /// Try Again
  public static let searchEmptyRetry = L10n.tr("Localizable", "search_empty_retry", fallback: "Try Again")
  /// No results for “%@”
  public static func searchEmptyTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "search_empty_title", String(describing: p1), fallback: "No results for “%@”")
  }
  /// Find movies, shows and people
  public static let searchIdlePrompt = L10n.tr("Localizable", "search_idle_prompt", fallback: "Find movies, shows and people")
  /// Collection
  public static let searchKindCollection = L10n.tr("Localizable", "search_kind_collection", fallback: "Collection")
  /// Company
  public static let searchKindCompany = L10n.tr("Localizable", "search_kind_company", fallback: "Company")
  /// Keyword
  public static let searchKindKeyword = L10n.tr("Localizable", "search_kind_keyword", fallback: "Keyword")
  /// Movie
  public static let searchKindMovie = L10n.tr("Localizable", "search_kind_movie", fallback: "Movie")
  /// Person
  public static let searchKindPerson = L10n.tr("Localizable", "search_kind_person", fallback: "Person")
  /// TV Show
  public static let searchKindTvShow = L10n.tr("Localizable", "search_kind_tv_show", fallback: "TV Show")
  /// Known for %@
  public static func searchKnownFor(_ p1: Any) -> String {
    return L10n.tr("Localizable", "search_known_for", String(describing: p1), fallback: "Known for %@")
  }
  /// Movies, shows, people
  public static let searchPrompt = L10n.tr("Localizable", "search_prompt", fallback: "Movies, shows, people")
  /// Rated %@ out of 10
  public static func searchRatingAccessibility(_ p1: Any) -> String {
    return L10n.tr("Localizable", "search_rating_accessibility", String(describing: p1), fallback: "Rated %@ out of 10")
  }
  /// Clear
  public static let searchRecentsClear = L10n.tr("Localizable", "search_recents_clear", fallback: "Clear")
  /// Remove
  public static let searchRecentsRemove = L10n.tr("Localizable", "search_recents_remove", fallback: "Remove")
  /// Recent Searches
  public static let searchRecentsTitle = L10n.tr("Localizable", "search_recents_title", fallback: "Recent Searches")
  /// All
  public static let searchScopeAll = L10n.tr("Localizable", "search_scope_all", fallback: "All")
  /// Collections
  public static let searchScopeCollections = L10n.tr("Localizable", "search_scope_collections", fallback: "Collections")
  /// Companies
  public static let searchScopeCompanies = L10n.tr("Localizable", "search_scope_companies", fallback: "Companies")
  /// Keywords
  public static let searchScopeKeywords = L10n.tr("Localizable", "search_scope_keywords", fallback: "Keywords")
  /// Movies
  public static let searchScopeMovies = L10n.tr("Localizable", "search_scope_movies", fallback: "Movies")
  /// People
  public static let searchScopePeople = L10n.tr("Localizable", "search_scope_people", fallback: "People")
  /// TV Shows
  public static let searchScopeTv = L10n.tr("Localizable", "search_scope_tv", fallback: "TV Shows")
  /// Trending Today
  public static let searchTrendingTitle = L10n.tr("Localizable", "search_trending_title", fallback: "Trending Today")
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
