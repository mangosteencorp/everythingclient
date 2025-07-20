// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  /// Now Playing
  public static let feedNowPlaying = L10n.tr("Localizable", "feed_now_playing", fallback: "Now Playing")
  /// Popular
  public static let feedPopular = L10n.tr("Localizable", "feed_popular", fallback: "Popular")
  /// Top Rated
  public static let feedTopRated = L10n.tr("Localizable", "feed_top_rated", fallback: "Top Rated")
  /// Upcoming
  public static let feedUpcoming = L10n.tr("Localizable", "feed_upcoming", fallback: "Upcoming")
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
  /// Localizable.strings
  ///   everythingclient
  /// 
  ///   Created by Quang on 2024-09-30.
  public static let playingLoading = L10n.tr("Localizable", "playing_loading", fallback: "Loading...")
  /// Now Playing
  public static let playingTitle = L10n.tr("Localizable", "playing_title", fallback: "Now Playing")
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
