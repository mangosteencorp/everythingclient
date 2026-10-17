#if canImport(SwiftfinLib)
import SwiftfinLib
#endif

/// Swiftfin owns the lock and one-time setup flag, so every entry point may call this safely.
enum SwiftfinRuntime {
    static func configureIfNeeded() {
        #if canImport(SwiftfinLib)
        SwiftfinLibrary.configure()
        #endif
    }
}
