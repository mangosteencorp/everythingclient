// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  /// Spoken while restoring the saved Plex session.
  public static let plexConnectionLoading = L10n.tr("Localizable", "plex_connection_loading", fallback: "Loading Plex connection")
  /// Could not connect to Plex.
  public static let plexErrorGeneric = L10n.tr("Localizable", "plex_error_generic", fallback: "Could not connect to Plex.")
  /// None of your Plex servers could be reached.
  public static let plexErrorNoReachableServer = L10n.tr("Localizable", "plex_error_no_reachable_server", fallback: "None of your Plex servers could be reached.")
  /// None of your Plex servers has a movie or TV library.
  public static let plexErrorNoServerWithContent = L10n.tr("Localizable", "plex_error_no_server_with_content", fallback: "None of your Plex servers has a movie or TV library.")
  /// The sign-in code expired before it was approved.
  public static let plexErrorPinExpired = L10n.tr("Localizable", "plex_error_pin_expired", fallback: "The sign-in code expired before it was approved.")
  /// Shown on a movie page or in the player when no Plex server is signed in.
  public static let plexLibraryNotConnected = L10n.tr("Localizable", "plex_library_not_connected", fallback: "Sign in to Plex in Settings to watch from your server.")
  /// This movie could not be played from Plex.
  public static let plexPlaybackFailed = L10n.tr("Localizable", "plex_playback_failed", fallback: "This movie could not be played from Plex.")
  /// Spoken label of the button that closes the Plex movie player.
  public static let plexPlayerClose = L10n.tr("Localizable", "plex_player_close", fallback: "Close player")
  /// Settings section header for the Plex account.
  public static let plexSectionTitle = L10n.tr("Localizable", "plex_section_title", fallback: "Plex")
  /// Sign in with Plex
  public static let plexSignIn = L10n.tr("Localizable", "plex_sign_in", fallback: "Sign in with Plex")
  /// Stops waiting for browser authorization.
  public static let plexSignInCancel = L10n.tr("Localizable", "plex_sign_in_cancel", fallback: "Cancel")
  /// Label for the code the user confirms on plex.tv.
  public static let plexSignInCode = L10n.tr("Localizable", "plex_sign_in_code", fallback: "Sign-in code")
  /// Open Plex sign-in
  public static let plexSignInOpen = L10n.tr("Localizable", "plex_sign_in_open", fallback: "Open Plex sign-in")
  /// Shown while the user approves the sign-in in the browser.
  public static let plexSignInWaiting = L10n.tr("Localizable", "plex_sign_in_waiting", fallback: "Waiting for browser authorization…")
  /// Sign out
  public static let plexSignOut = L10n.tr("Localizable", "plex_sign_out", fallback: "Sign out")
  /// Try again
  public static let plexTryAgain = L10n.tr("Localizable", "plex_try_again", fallback: "Try again")
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
