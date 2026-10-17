#if canImport(SwiftfinLib)
import SwiftfinLib
#endif
import SwiftUI

/// Opens the matched movie's own Swiftfin page without starting playback.
@available(iOS 16.0, *)
public struct JellyfinMovieDetailView: View {
    @Environment(\.dismiss) private var dismiss
    private let match: JellyfinMovieMatch

    /// Enable the bridge only after the Swiftfin dependency includes the public movie-page API.
    public static var isAvailable: Bool {
        #if canImport(SwiftfinLib) && SWIFTFIN_LAUNCHER_BRIDGE
        true
        #else
        false
        #endif
    }

    public init(match: JellyfinMovieMatch) {
        self.match = match
        SwiftfinRuntime.configureIfNeeded()
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            #if canImport(SwiftfinLib) && SWIFTFIN_LAUNCHER_BRIDGE
            match.item.map(SwiftfinLibrary.movieDetails(for:)) ?? SwiftfinLibrary.movieDetails(matching: .keyword(match.title))
            #else
            Text(L10n.jellyfinDetailsUnavailable)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            #endif

            Button {
                SwiftfinWindowAppearanceGuard.swiftfinWillDismiss()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .padding(16)
            }
            .accessibilityLabel(L10n.jellyfinDetailsClose)
            .accessibilityIdentifier("jellyfin.details.close.button")
        }
        .onAppear { SwiftfinWindowAppearanceGuard.swiftfinWillAppear() }
        .onDisappear { SwiftfinWindowAppearanceGuard.swiftfinDidDisappear() }
    }
}

#if DEBUG
#Preview {
    JellyfinMovieDetailView(match: JellyfinMovieMatch(
        id: "preview",
        title: "Dune",
        runtimeSeconds: 9315,
        playedFraction: 0,
        resumeSeconds: 0,
        isPlayed: false
    ))
}
#endif
