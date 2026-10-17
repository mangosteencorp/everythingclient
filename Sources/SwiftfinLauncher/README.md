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

The currently pinned `quangDecember/Swiftfin` revision exposes movie lookup and playback, but its session data and
`ItemView` are internal. Therefore `JellyfinMovieDetailView.isAvailable` and `SwiftfinSessionService.isAvailable` are
currently false. Movie details keeps Open disabled and Settings shows that connection details are unavailable;
neither reports a false signed-out state nor substitutes playback for opening a page.

The reviewable [upstream patch](Upstream/swiftfin-launcher.patch) adds these public APIs inside Swiftfin:

- `SwiftfinLibrary.currentConnection()` returns only the server name and username, without exposing credentials.
- `SwiftfinLibrary.movieDetails(for:)` and `movieDetails(matching:)` restore the current session and present Swiftfin's
  actual `ItemView` with its navigation environment. They do not start a player.

Apply the patch in a clean checkout of the Swiftfin fork, build and publish that revision, then update this package's
Swiftfin dependency and lockfile. Once the dependency includes those APIs, add
`swiftSettings: [.define("SWIFTFIN_LAUNCHER_BRIDGE")]` to the **SwiftfinLauncher** target in `Package.swift`.
The flag belongs to that target; setting it only on the host app does not affect package compilation. Do not enable it
against the current revision. No generated checkout or private Swiftfin database is modified by this library.
