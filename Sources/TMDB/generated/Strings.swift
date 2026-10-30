// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  /// Appearance
  public static let settingsAppearance = L10n.tr("Localizable", "settings_appearance", fallback: "Appearance")
  /// Close
  public static let settingsClose = L10n.tr("Localizable", "settings_close", fallback: "Close")
  /// Launch Jellyfin by Swiftfin
  public static let settingsLaunchSwiftfin = L10n.tr("Localizable", "settings_launch_swiftfin", fallback: "Launch Jellyfin by Swiftfin")
  /// Media Server
  public static let settingsMediaServer = L10n.tr("Localizable", "settings_media_server", fallback: "Media Server")
  /// More settings coming soon.
  public static let settingsMoreComing = L10n.tr("Localizable", "settings_more_coming", fallback: "More settings coming soon.")
  /// Open Samples
  public static let settingsOpenSamples = L10n.tr("Localizable", "settings_open_samples", fallback: "Open Samples")
  /// Movie projector coin
  public static let settingsProjectorCoin = L10n.tr("Localizable", "settings_projector_coin", fallback: "Movie projector coin")
  /// Settings
  public static let settingsTitle = L10n.tr("Localizable", "settings_title", fallback: "Settings")
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
