#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import Foundation

/// System-appearance queries, bridged across UIKit and AppKit.
///
/// Mirrors the shim style already used by the SwiftGen output in
/// `Shared_UI_Support/generated/Fonts.swift`: a single symbol per platform concept,
/// resolved once here so feature code never reaches for `UITraitCollection`/`NSAppearance`.
public enum PlatformAppearance {
    /// Whether the system is currently rendering in a dark appearance.
    @MainActor
    public static var isDarkMode: Bool {
        #if canImport(UIKit)
        return UITraitCollection.current.userInterfaceStyle == .dark
        #elseif canImport(AppKit)
        let appearance = NSApp?.effectiveAppearance ?? NSAppearance.currentDrawing()
        return appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        #else
        return false
        #endif
    }

    /// Registers `observer` for every notification that signals a system appearance change
    /// on the current platform.
    ///
    /// On macOS this is the distributed `AppleInterfaceThemeChangedNotification`, which is the
    /// only reliable signal for a light/dark switch while the app is running. On iOS there is no
    /// such notification — trait changes are delivered through the responder chain — so we settle
    /// for re-checking on foreground.
    @MainActor
    public static func addAppearanceChangeObserver(_ observer: Any, selector: Selector) {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            observer,
            selector: selector,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        #elseif canImport(AppKit)
        NotificationCenter.default.addObserver(
            observer,
            selector: selector,
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        DistributedNotificationCenter.default.addObserver(
            observer,
            selector: selector,
            name: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
        #endif
    }

    /// Undoes `addAppearanceChangeObserver`. Safe to call from `deinit`.
    public static func removeAppearanceChangeObserver(_ observer: Any) {
        NotificationCenter.default.removeObserver(observer)
        #if canImport(AppKit) && !canImport(UIKit)
        DistributedNotificationCenter.default.removeObserver(observer)
        #endif
    }
}
