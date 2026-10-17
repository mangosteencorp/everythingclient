# PlexLauncher

An object-oriented session coordinator over `Plex_Shared_Backend`. It handles browser sign-in state, choosing and
remembering a working server, and reopening that server on the next launch. `PlexConnection.api` exposes the backend's
full API for browsing, watch state, media requests, downloads, playlists and other Plex features.

Depend on the `PlexLauncher` library product. Import `Plex_Shared_Backend` when using its configuration and query types.

```swift
import PlexLauncher
import Plex_Shared_Backend

// Keep this identifier stable across launches; the app owns its persistence.
let identity = try PlexClientIdentity(
    identifier: savedClientID, product: "My App", version: "1", platform: "iOS"
)
let launcher = PlexLauncher(
    identity: identity,
    credentials: PlexKeychainCredentialStore(
        service: "com.example.myapp",
        account: "plex-personal" // Choose a different item for another app profile.
    )
)

// First try the saved session. No PIN or browser is needed.
if let connection = try await launcher.resume() {
    let sections = connection.libraries
    let name = connection.name
    let user = connection.accountName
    // Retain `launcher` for the session's lifetime.
}
```

For a new account, the app opens the authorization URL and controls polling:

```swift
let signIn = try await launcher.beginSignIn()
openInBrowser(signIn.authorizationURL)
while !(try await launcher.completeSignIn(pinID: signIn.id)) {
    try await Task.sleep(for: .seconds(2))
}

// Choose a server, or let the backend rank those with movie/show libraries.
let servers = try await launcher.servers()
let connection = try await launcher.connectBest()
// Alternatively: try await launcher.connect(to: chosenServer)

if let movies = connection.libraries.first(where: { $0.type == "movie" }) {
    let page = try await connection.api.items(sectionID: movies.key, page: PlexPagination(size: 50))
}
```

`completeSignIn` performs one poll and returns `false` while authorization is pending. Expired PINs throw
`PlexAPIError.pinExpired`. Cancel the polling task and call `await launcher.cancelSignIn()` when dismissing sign-in.
An existing session stays available until the new account is authorized and securely saved.

For a direct server connection, use its server token:

```swift
let connection = try await launcher.connect(baseURL: serverURL, token: serverToken)
```

This verifies the server identity and library access, saves the server credential and clears any previous account
association. It does not perform plex.tv sign-in. Plain HTTP requires `allowHTTP: true`, including when resuming.

`resume()` first checks the saved address against the saved machine identifier and loads its library sections. If the
address or token no longer works and an account token is saved, it rediscovers fresh addresses and a server token for
that same machine identifier. It never silently switches to another server. An account saved before a server was
chosen resumes by choosing the best available server. A failed or cancelled operation leaves stored credentials intact.
Older credentials without a machine identifier can resume at their saved address but cannot rediscover that server.

`await launcher.signOut()` clears the selected credential-store item and this launcher's connection. Release retained
`PlexConnection` objects when signing out; their API services contain the old server credential. Sign-out does not revoke
Plex's token remotely.

Use `any PlexLaunching` as the app's test boundary. For integration tests, inject `PlexAccountServing &
PlexAccountProfileServing`, `PlexServerConnecting`, `PlexCredentialStoring`, or `PlexHTTPTransport` in the initializer.
New sign-in, connection and resume operations supersede earlier work, which throws `CancellationError` before it can
save credentials or publish a connection. The library presents no UI and starts no background polling tasks.

## Running tests

The shared `Launcher_Tests` scheme covers `PlexLauncher`, `Plex_Shared_Backend` and `SwiftfinLauncher`:

```bash
scheme=Launcher_Tests bash .github/scripts/build.sh
```

Run the scheme's tests in Xcode after building. These suites use injected services and Security operations; they do not
require a Plex/Jellyfin account or Keychain entitlements on the package test runner.
