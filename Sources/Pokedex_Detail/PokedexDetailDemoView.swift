// iOS-only module: nothing in a macOS build depends on it (see `Package.swift`), but
// Xcode compiles every target of a local package regardless of reachability, so the
// guard is what actually keeps this out of the macOS build. It compiles to an empty
// module there. Removing these guards is the payoff of extracting a separate,
// iOS-only Package.swift.
#if canImport(UIKit)
import SwiftUI

#if DEBUG
public struct PokedexDetailDemoView: View {
    public init() {}

    public var body: some View {
        VStack {
            Image(systemName: "leaf")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Pokedex Detail Demo")
                .font(.title)
                .padding()

            Text("This demo will showcase the Pokedex Detail functionality")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()

            // TODO: Implement actual Pokedex Detail demo
            Text("Coming soon...")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding()
    }
}

#if DEBUG
#Preview {
    PokedexDetailDemoView()
}
#endif
#endif
#endif
