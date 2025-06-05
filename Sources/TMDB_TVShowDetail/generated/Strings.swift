// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  public enum Tvshow {
    public enum Detail {
      /// %.1f (%d votes)
      public static func averageVote(_ p1: Float, _ p2: Int) -> String {
        return L10n.tr("Localizable", "tvshow.detail.average_vote", p1, p2, fallback: "%.1f (%d votes)")
      }
      /// Created by
      public static let createdBy = L10n.tr("Localizable", "tvshow.detail.created_by", fallback: "Created by")
      /// Details
      public static let details = L10n.tr("Localizable", "tvshow.detail.details", fallback: "Details")
      /// Error: %@
      public static func error(_ p1: Any) -> String {
        return L10n.tr("Localizable", "tvshow.detail.error", String(describing: p1), fallback: "Error: %@")
      }
      /// First air date: %@
      public static func firstAirDate(_ p1: Any) -> String {
        return L10n.tr("Localizable", "tvshow.detail.first_air_date", String(describing: p1), fallback: "First air date: %@")
      }
      /// Genres
      public static let genres = L10n.tr("Localizable", "tvshow.detail.genres", fallback: "Genres")
      /// Last air date: %@
      public static func lastAirDate(_ p1: Any) -> String {
        return L10n.tr("Localizable", "tvshow.detail.last_air_date", String(describing: p1), fallback: "Last air date: %@")
      }
      /// Loading TV Show Details...
      public static let loading = L10n.tr("Localizable", "tvshow.detail.loading", fallback: "Loading TV Show Details...")
      /// Number of episodes: %d
      public static func numberOfEpisodes(_ p1: Int) -> String {
        return L10n.tr("Localizable", "tvshow.detail.number_of_episodes", p1, fallback: "Number of episodes: %d")
      }
      /// Number of seasons: %d
      public static func numberOfSeasons(_ p1: Int) -> String {
        return L10n.tr("Localizable", "tvshow.detail.number_of_seasons", p1, fallback: "Number of seasons: %d")
      }
      /// Overview
      public static let overview = L10n.tr("Localizable", "tvshow.detail.overview", fallback: "Overview")
      /// Seasons
      public static let seasons = L10n.tr("Localizable", "tvshow.detail.seasons", fallback: "Seasons")
      /// Status: %@
      public static func status(_ p1: Any) -> String {
        return L10n.tr("Localizable", "tvshow.detail.status", String(describing: p1), fallback: "Status: %@")
      }
      /// TBA
      public static let tba = L10n.tr("Localizable", "tvshow.detail.tba", fallback: "TBA")
    }
  }
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
