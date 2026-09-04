#if canImport(UIKit)
import UIKit
#endif

/// Device-idiom queries, bridged across UIKit and AppKit.
public enum PlatformIdiom {
    /// Whether the app is running somewhere with iPad-class layout affordances.
    ///
    /// On macOS this is `false`: a Mac window is resizable, so layouts should be chosen from the
    /// size class rather than a fixed idiom, and every `isPad`-gated design in this app is an
    /// iPad-specific *variant* rather than a "roomy window" variant.
    public static var isPad: Bool {
        #if canImport(UIKit) && !os(watchOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }
}
