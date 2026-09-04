import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Opens URLs in the system default handler, bridged across UIKit and AppKit.
public enum PlatformURLOpener {
    @MainActor
    public static func open(_ url: URL) {
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }

    /// The app's own entry in system Settings, when the platform has one.
    ///
    /// macOS has no per-app settings deep link, so callers must handle `nil`.
    public static var appSettingsURL: URL? {
        #if canImport(UIKit)
        return URL(string: UIApplication.openSettingsURLString)
        #else
        return nil
        #endif
    }
}
