#if canImport(SwiftfinLib)
import SwiftfinLib
#endif

/// Swiftfin's one-time process setup (CoreStore stack, logging, Nuke pipeline).
///
/// It has to run before anything reads Swiftfin's stored servers/users, so both the full-screen
/// Swiftfin app and the Jellyfin library lookup go through here rather than each keeping their own
/// "have I configured yet" flag — `LoggingSystem.bootstrap` traps if it runs twice.
enum SwiftfinRuntime {
    // Always reached from the main thread (a `View` init or a `@MainActor` view model), but the
    // callers aren't statically isolated, so the flag is opted out of concurrency checking.
    nonisolated(unsafe) private static var isConfigured = false

    static func configureIfNeeded() {
        guard !isConfigured else { return }
        #if canImport(SwiftfinLib)
        SwiftfinLibrary.configure()
        #endif
        isConfigured = true
    }
}
