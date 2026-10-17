// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  /// Cast
  public static let castSectionTitle = L10n.tr("Localizable", "cast_section_title", fallback: "Cast")
  /// Crew
  public static let crewSectionTitle = L10n.tr("Localizable", "crew_section_title", fallback: "Crew")
  /// Error: %@
  public static func errorFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "error_format", String(describing: p1), fallback: "Error: %@")
  }
  /// Checking your Jellyfin library...
  public static let jellyfinCheckingLibrary = L10n.tr("Localizable", "jellyfin_checking_library", fallback: "Checking your Jellyfin library...")
  /// %@ in
  public static func jellyfinElapsedFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "jellyfin_elapsed_format", String(describing: p1), fallback: "%@ in")
  }
  /// Open
  public static let jellyfinOpen = L10n.tr("Localizable", "jellyfin_open", fallback: "Open")
  /// Open this movie's page in Swiftfin without starting playback.
  public static let jellyfinOpenHint = L10n.tr("Localizable", "jellyfin_open_hint", fallback: "Open this movie's page in Swiftfin without starting playback.")
  /// Opening movie pages in Swiftfin is unavailable in this build.
  public static let jellyfinOpenUnavailable = L10n.tr("Localizable", "jellyfin_open_unavailable", fallback: "Opening movie pages in Swiftfin is unavailable in this build.")
  /// Play
  public static let jellyfinPlay = L10n.tr("Localizable", "jellyfin_play", fallback: "Play")
  /// %@ left
  public static func jellyfinRemainingFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "jellyfin_remaining_format", String(describing: p1), fallback: "%@ left")
  }
  /// Resume from %@.
  public static func jellyfinResumeHint(_ p1: Any) -> String {
    return L10n.tr("Localizable", "jellyfin_resume_hint", String(describing: p1), fallback: "Resume from %@.")
  }
  /// On Jellyfin
  public static let jellyfinSectionTitle = L10n.tr("Localizable", "jellyfin_section_title", fallback: "On Jellyfin")
  /// Watched
  public static let jellyfinWatched = L10n.tr("Localizable", "jellyfin_watched", fallback: "Watched")
  /// %d%% watched • %@
  public static func jellyfinWatchedProgressFormat(_ p1: Int, _ p2: Any) -> String {
    return L10n.tr("Localizable", "jellyfin_watched_progress_format", p1, String(describing: p2), fallback: "%d%% watched • %@")
  }
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
