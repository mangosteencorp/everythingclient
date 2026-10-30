# PlexBackendDemo

A SwiftUI app that exercises `Plex_Shared_Backend` end to end: PIN sign-in, automatic server choice, browsing, playback
with progress reporting, original-file downloads, offline mode with queued watch sync, playlists, collections and server
admin tools. It wires the backend services itself through one `@Observable` `DemoSession` instead of using
`PlexLauncher`, so it also serves as a reference integration. The project is part of `everythingclient.xcworkspace` and
links the `Plex_Shared_Backend` library product.

## Run it

Open `everythingclient.xcworkspace`, choose the `PlexBackendDemo` scheme and an iOS 27.2 simulator, then Run. The target
also lists macOS and visionOS as supported platforms. On launch the app reopens the last saved session, if there is one.

No account is needed to look around. Tap **Account → Explore sample library**, or add the `--fixtures` launch argument
(Edit Scheme → Run → Arguments). Sample mode answers every request from `DemoResponses.json` through
`DemoFixtureTransport` and never contacts plex.tv or a media server. A yellow banner marks it. Browsing, details,
filters, collections, playlists and download plans work, but nothing can be played or transferred.

## Sign in to a real server

In **Account**, tap **Sign in with Plex**. The app shows a sign-in code and an **Open Plex sign-in** button. Approve the
code in the browser; the app polls every 2 seconds until it is authorized or expires. It then lists the account's
servers and connects.

- **Server → Automatic** (the default) lets the backend try every server and keep the best working one with a movie or
  TV library. Account shows why it won, for example `Local · 38ms`.
- Choosing a named server connects only that one. Choose **Automatic** again to re-rank. **Refresh servers** reruns
  discovery.
- **Load home profiles** lists Plex Home users. **Switch profile** asks for the PIN of protected profiles.
- **Advanced connection settings** connects to a server URL (including any proxy prefix) with a server access token,
  without plex.tv. Only HTTPS is accepted unless **Allow an unencrypted HTTP connection** is on. HTTP sends the token
  unencrypted, so use it only on a trusted local network.

The session (account token, account name and the connected server's credential) is saved in the Keychain under service
`com.prototype.PlexBackendDemo`, account `plex-session`. On the next launch the saved server opens from cache at once;
with a signed-in account, discovery then looks up fresh addresses. **Sign out** clears that Keychain item and cancels
running transfers. Completed downloads and queued watch changes stay on the device.

Everything else lives in the app's Application Support folder under `PlexBackendDemo/`: `ResponseCache/` (token-free
responses and artwork, used offline), `WatchSync.json` (queued watch changes) and `Downloads/` (files plus a
`downloads.json` manifest of completed items). `UserDefaults` keeps the client identifier (`plex-demo-client-id`) and
the cURL logging switch (`plex-demo-curl-logging`).

## What to try

- **Home**: Continue Watching (merged with On Deck) and the server's home hubs. **See all** opens a hub's full list.
- **Library**: each section has Browse (server-advertised sorts, boolean filters and genres in the toolbar menu),
  Recommended, Collections and Folders. Lists page with **Load more**. Also **Playlists** and **Shared with you**.
- **Search**: server-wide search across movies, shows and collections.
- **Item details**: play or resume, **Play all** and **Shuffle** through a server play queue, watched state, a five-star
  rating, remove from Continue Watching, add to a playlist or collection, version, audio and subtitle choice (saved on
  the server), **Find subtitles online**, cast and crew, extras and related hubs. **More** refreshes metadata or deletes
  (server admin only).
- **Player**: direct-plays MP4, M4V and MOV with H.264 or HEVC and requests an HLS transcode otherwise. It resumes from
  the saved position, offers Skip intro/credits and **Next in queue**, and reports `/:/timeline` progress every 10
  seconds and on stop. A stop that cannot be sent is queued for sync.
- **Downloads**: **Download for offline** builds a download plan for the original file, optionally with external
  subtitles. Transfers run one at a time while the app is open and can be paused, resumed, cancelled or retried.
  Completed items play from disk, can be exported, and keep their own server for watch sync. **Sync now** pushes queued
  changes. Only completed downloads survive a relaunch.
- **Offline mode**: a switch in Account. Screens then read from the response cache (anything opened before), watch
  changes are queued, and an orange banner offers **Go online**. The app also goes offline by itself when the saved
  server or plex.tv cannot be reached.
- **Playlists**: Library → Playlists lists video playlists; **+** creates one. Swipe removes an entry; **More** deletes
  the playlist.
- **Server tools** (Account, while connected): server info, watched threshold, Live TV DVR count, background activities
  (swipe to cancel), per-library scan, metadata refresh, analysis and empty trash, live server notifications, a raw
  request console for any server-relative path, and **Clear offline cache**. Non-GET raw requests ask first.
- **Network log**: Account → Developer → **Log network calls as cURL** writes every request as a `curl` command to
  Xcode's console (`Logger` subsystem `Plex_Shared_Backend`, category `curl`) and to **Network log** (newest 200,
  shareable). **Hide tokens and PINs** is on at each launch; with it off, the log contains working credentials.

## Code map

All app sources are in `PlexBackendDemo/`.

- `PlexBackendDemoApp.swift`, `ContentView.swift`: entry point, `--fixtures` or restore at launch, the five tabs, the
  shared error alert and the offline/sample banner.
- `DemoSession.swift`: app-wide state, client identity, services and transports, Keychain save and restore, PIN
  sign-in, home profiles, sign-out and the cURL logging switch.
- `DemoSession+Connection.swift`: discovery, Automatic or chosen server, manual URL and token, the per-server caching
  transport and sample mode.
- `DemoSession+Sync.swift`: offline mode, watched state and playback progress with the watch-sync queue.
- `HomeView.swift`, `LibraryView.swift`, `SearchView.swift`, `PlaylistsView.swift`: browsing screens.
- `ItemDetailView.swift`, `MediaInfoViews.swift`: the item page and its actions, stream selection, the download plan
  sheet and subtitle search.
- `PlayerView.swift`: `PlayerModel` (direct play or transcode, markers, queue, timeline reports) and
  `DemoPlayerFactory`, which passes the token in the player URL.
- `DownloadsView.swift`, `DemoTransfers.swift`: the offline library and a serial foreground download queue.
- `AccountView.swift`: sign-in, server picker, home profiles, offline switch, manual connection and the network log.
- `ServerToolsView.swift`: server status, activities, library maintenance, notifications and raw requests.
- `PagedItemsView.swift`, `DemoComponents.swift`: the paged list model, rows, shelves, artwork and shared navigation.
- `DemoFixtures.swift`, `DemoResponses.json`: the sample-mode transport and its responses, looked up by
  `path?name=value`, then `path`, then `*`.
- `DemoDiagnostics.swift`: redacted JSON for raw responses and user-facing error messages.

`Demo.xcconfig`, next to the project, is the base configuration for the app target's Debug and Release builds.

## Tests

The `PlexBackendDemo` scheme's test action runs two bundles:

- `PlexBackendDemoTests`: Swift Testing suites hosted in the app. They build sessions with an in-memory credential
  store, a temporary storage folder and stubbed services, so they need no account and never touch the Keychain. The
  host app skips its saved-session restore while tests run.
- `PlexBackendDemoUITests`: XCTest smoke tests that launch with `--fixtures`, so they also need no account.

From the repository root:

```bash
# Build the app and both test bundles for the simulator.
scheme=PlexBackendDemo bash .github/scripts/build.sh

# Run every test, or add -only-testing:PlexBackendDemoTests (or PlexBackendDemoUITests) for one bundle.
xcodebuild test -workspace everythingclient.xcworkspace -scheme PlexBackendDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Any simulator with an iOS 27.2 runtime works.

## Related docs

- [Plex_Shared_Backend](../../Sources/Plex_Shared_Backend/README.md): the backend's API reference, HTTP API map and
  sample responses.
- [Save and resume without signing in again](../../Sources/Plex_Shared_Backend/README.md#save-and-resume-without-signing-in-again):
  the persistence pattern `DemoSession` follows.
- [PlexLauncher](../../Sources/PlexLauncher/README.md): sign-in, server choice and resume packaged behind one object,
  for apps that don't need to wire the services themselves.
