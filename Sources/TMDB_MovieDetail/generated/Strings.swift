// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  /// Couldn't load cast & crew
  public static let castLoadFailed = L10n.tr("Localizable", "cast_load_failed", fallback: "Couldn't load cast & crew")
  /// Cast
  public static let castSectionTitle = L10n.tr("Localizable", "cast_section_title", fallback: "Cast")
  /// Crew
  public static let crewSectionTitle = L10n.tr("Localizable", "crew_section_title", fallback: "Crew")
  /// Couldn't load movie details
  public static let detailLoadFailed = L10n.tr("Localizable", "detail_load_failed", fallback: "Couldn't load movie details")
  /// Couldn't check your Jellyfin library
  public static let jellyfinLoadFailed = L10n.tr("Localizable", "jellyfin_load_failed", fallback: "Couldn't check your Jellyfin library")
  /// Keywords
  public static let keywordsTitle = L10n.tr("Localizable", "keywords_title", fallback: "Keywords")
  /// Locations
  public static let locationsTitle = L10n.tr("Localizable", "locations_title", fallback: "Locations")
  /// %@ minutes
  public static func minutesFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "minutes_format", String(describing: p1), fallback: "%@ minutes")
  }
  /// Overview:
  public static let overviewTitle = L10n.tr("Localizable", "overview_title", fallback: "Overview:")
  /// Photos
  public static let photosSectionTitle = L10n.tr("Localizable", "photos_section_title", fallback: "Photos")
  /// Open Pokédex
  public static let pokedexOpen = L10n.tr("Localizable", "pokedex_open", fallback: "Open Pokédex")
  /// Pokédex
  public static let pokedexTitle = L10n.tr("Localizable", "pokedex_title", fallback: "Pokédex")
  /// %@ ratings
  public static func ratingsFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "ratings_format", String(describing: p1), fallback: "%@ ratings")
  }
  /// Less
  public static let readLess = L10n.tr("Localizable", "read_less", fallback: "Less")
  /// Read more
  public static let readMore = L10n.tr("Localizable", "read_more", fallback: "Read more")
  /// Try Again
  public static let retryButtonTitle = L10n.tr("Localizable", "retry_button_title", fallback: "Try Again")
  /// See all
  public static let seeAll = L10n.tr("Localizable", "see_all", fallback: "See all")
  /// •
  public static let separator = L10n.tr("Localizable", "separator", fallback: "•")
  /// Couldn't load the soundtrack
  public static let soundtrackLoadFailed = L10n.tr("Localizable", "soundtrack_load_failed", fallback: "Couldn't load the soundtrack")
  /// Couldn't load where to watch
  public static let watchProvidersLoadFailed = L10n.tr("Localizable", "watch_providers_load_failed", fallback: "Couldn't load where to watch")
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
