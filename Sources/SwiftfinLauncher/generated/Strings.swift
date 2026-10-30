// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  /// Close movie page
  public static let jellyfinDetailsClose = L10n.tr("Localizable", "jellyfin_details_close", fallback: "Close movie page")
  /// Opening movie pages in Swiftfin is unavailable in this build.
  public static let jellyfinDetailsUnavailable = L10n.tr("Localizable", "jellyfin_details_unavailable", fallback: "Opening movie pages in Swiftfin is unavailable in this build.")
  /// Jellyfin playback is unavailable in this build.
  public static let jellyfinPlaybackUnavailable = L10n.tr("Localizable", "jellyfin_playback_unavailable", fallback: "Jellyfin playback is unavailable in this build.")
  /// Close player
  public static let jellyfinPlayerClose = L10n.tr("Localizable", "jellyfin_player_close", fallback: "Close player")
  /// Close Swiftfin
  public static let swiftfinClose = L10n.tr("Localizable", "swiftfin_close", fallback: "Close Swiftfin")
  /// Could not load the connected server.
  public static let swiftfinConnectionFailed = L10n.tr("Localizable", "swiftfin_connection_failed", fallback: "Could not load the connected server.")
  /// Spoken while restoring Swiftfin's signed-in session.
  public static let swiftfinConnectionLoading = L10n.tr("Localizable", "swiftfin_connection_loading", fallback: "Loading connected server")
  /// No Jellyfin server is connected.
  public static let swiftfinConnectionNotConnected = L10n.tr("Localizable", "swiftfin_connection_not_connected", fallback: "No Jellyfin server is connected.")
  /// Current dependency does not expose its connected session to the host.
  public static let swiftfinConnectionUnavailable = L10n.tr("Localizable", "swiftfin_connection_unavailable", fallback: "Connection details require an updated Swiftfin library.")
  /// Swiftfin is unavailable in this build.
  public static let swiftfinUnavailable = L10n.tr("Localizable", "swiftfin_unavailable", fallback: "Swiftfin is unavailable in this build.")
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
