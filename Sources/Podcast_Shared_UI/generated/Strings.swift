// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  ///  · 
  public static let episodeDetailsSeparator = L10n.tr("Localizable", "episode_details_separator", fallback: " · ")
  /// Loading
  public static let loading = L10n.tr("Localizable", "loading", fallback: "Loading")
  /// Pause
  public static let pause = L10n.tr("Localizable", "pause", fallback: "Pause")
  /// Play
  public static let play = L10n.tr("Localizable", "play", fallback: "Play")
  /// Couldn't play this episode.
  public static let playbackFailed = L10n.tr("Localizable", "playback_failed", fallback: "Couldn't play this episode.")
  /// Playback progress
  public static let playbackProgress = L10n.tr("Localizable", "playback_progress", fallback: "Playback progress")
  /// -%@
  public static func remainingTimeFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "remaining_time_format", String(describing: p1), fallback: "-%@")
  }
  /// Skip back %d seconds
  public static func skipBackFormat(_ p1: Int) -> String {
    return L10n.tr("Localizable", "skip_back_format", p1, fallback: "Skip back %d seconds")
  }
  /// Skip forward %d seconds
  public static func skipForwardFormat(_ p1: Int) -> String {
    return L10n.tr("Localizable", "skip_forward_format", p1, fallback: "Skip forward %d seconds")
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
