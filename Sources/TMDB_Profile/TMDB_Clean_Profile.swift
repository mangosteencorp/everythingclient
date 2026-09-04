// iOS-only module: nothing in a macOS build depends on it (see `Package.swift`), but
// Xcode compiles every target of a local package regardless of reachability, so the
// guard is what actually keeps this out of the macOS build. It compiles to an empty
// module there. Removing these guards is the payoff of extracting a separate,
// iOS-only Package.swift.
#if canImport(UIKit)
import Swinject
import TMDB_Shared_Backend
// swiftlint:disable type_name
public struct TMDB_Profile {
    public static func configure(_ container: Container) {
        let assembly = ProfileAssembly()
        assembly.assemble(container: container)
    }

    private init() {}
}

// swiftlint:enable type_name
#endif
