# SwiftfinLauncher

A small SwiftUI library around the embedded Swiftfin client. Import `SwiftfinLauncher` to use:

- `SwiftfinLaunchView()` for the full client.
- `SwiftfinJellyfinLibraryService` / `JellyfinLibraryServicing` to find a movie in the signed-in library.
- `JellyfinMoviePlayerView(match:)` for playback of the exact matched item.
- `JellyfinMovieDetailView(match:)` for the native Swiftfin movie page, without autoplay.
- `SwiftfinSessionServicing` and `SwiftfinConnectionModel` for the connected server/user display.

Swiftfin owns authentication and its stored sessions. Hosts can inject `JellyfinLibraryServicing` and
`SwiftfinSessionServicing` in tests without linking the SDK into feature code. Swiftfin is linked on iOS only.

## Dependency API extension

The pinned Swiftfin revision `6cf78d0398b6d352ed7214048b3bd246b31b4d21` provides the host APIs used by this adapter:

- `SwiftfinLibrary.currentConnection()` returns only the server name and username, without exposing credentials.
- `SwiftfinLibrary.movieDetails(for:)` and `movieDetails(matching:)` restore the current session and present Swiftfin's
  actual `ItemView` with its navigation environment. They do not start a player.

`SWIFTFIN_LAUNCHER_BRIDGE` is enabled on the SwiftfinLauncher target. Connected server/user details and native movie-page
navigation are available on iOS builds that link SwiftfinLib. Swiftfin retains ownership of authentication and its
stored sessions. Builds without SwiftfinLib keep the unavailable states.

The [upstream patch](Upstream/swiftfin-launcher.patch) records the API extension for review. A movie's native provider
is scoped to its item ID so changing the requested movie recreates its retained state.
