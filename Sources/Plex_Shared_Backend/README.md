# Plex_Shared_Backend

A Swift client for plex.tv sign-in and Plex Media Server: discovery, connection, browsing, hubs, watch state,
collections, playlists, play queues, media requests, download plans, admin and live notifications. It uses Apple
frameworks only (Foundation, Security, CryptoKit, os, Synchronization). `PlexAccountService`, `PlexServerConnector` and
`PlexAPIService` each take a `PlexHTTPTransport`, so you can stub, cache or log the network.

## Quick integration

Depend on the `Plex_Shared_Backend` library product: inside this package, `.target(name: "MyFeature", dependencies:
["Plex_Shared_Backend"])`; an Xcode app in `everythingclient.xcworkspace` links the product, as `Rebuild/PlexBackendDemo`
does. Then:

```swift
import Plex_Shared_Backend

// Persist `identifier` and reuse it: plex.tv ties PINs and sessions to it.
let identity = try PlexClientIdentity(identifier: savedClientID, product: "EverythingClient", version: "1", platform: "iOS")
let account = PlexAccountService(identity: identity)

// 1. PIN sign-in. Opening the page, the polling cadence and cancellation are yours.
let pin = try await account.createPIN()
openInBrowser(try account.authorizationURL(code: pin.code))
var authToken: String?
while authToken == nil {
    try await Task.sleep(for: .seconds(2))
    authToken = try await account.pin(id: pin.id).authToken // throws PlexAPIError.pinExpired once the PIN lapses
}

// 2. Pick a server; the connector finds an address that answers as that server and loads its sections.
//    connectBest tries every server and keeps the best one with movies or shows; connect(to:identity:) takes one server.
guard let accountToken = authToken else { return }
let servers = try await account.servers(accountToken: accountToken)
let connection = try await PlexServerConnector().connectBest(among: servers, identity: identity).connection

// 3. Browse with the server-scoped configuration.
let api = PlexAPIService(configuration: connection.configuration)
guard let movies = connection.libraries.first(where: { $0.type == "movie" }) else { return }
let page = try await api.items(sectionID: movies.key, page: PlexPagination(size: 50))

// 4. Plan an original-file download and hand the requests to your own URLSession.
guard let movie = page.metadata.first else { return }
let plan = try await api.downloadPlan(ratingKey: movie.ratingKey)
let requests = plan.parts.flatMap { [$0.request] + $0.subtitles.map(\.request) }
```

Rules that matter:

- **Server token, never the account token.** `PlexServerResource.configuration(connectionIndex:identity:)` and the
  connector use each server's own `accessToken`; shared servers have their own, and a missing one fails instead of
  falling back to the account token.
- **HTTPS unless you opt in.** `connect(to:identity:allowHTTP:)` tries plain HTTP only with `allowHTTP: true`, and only
  after every HTTPS address. A manual `PlexServerConfiguration` accepts `http` URLs, so gate those yourself.
- **Automatic server choice.** `connectBest(among:identity:content:allowHTTP:)` skips dead servers, wrong identities and
  rejected or expired tokens, keeps those with movie or show sections, and ranks local > remote > relay, then reply
  time, then owned. Slower servers get 1.5 seconds after the first usable answer.
- **Tokens stay in headers.** `X-Plex-Token` is only ever a header: keys or queries carrying one fail with
  `PlexAPIError.invalidPath`, the default transport refuses cross-origin redirects, and errors never carry response
  bodies. Don't log request headers, and don't log `switchUser`'s URL: the profile PIN is a query item.
- **cURL logging is opt-in.** Wrap the transport in `PlexCurlLoggingTransport(logger: PlexCurlLogger(isEnabled: true))`
  (inside any `PlexCachingTransport` to log only real network calls) and give the same logger to
  `PlexEventSource(logger:)`. Tokens and PINs are redacted unless you set `redactsCredentials = false`.
- **Offline.** Wrap the transport in `PlexCachingTransport(upstream:cache:scope:)` with a `PlexDiskResponseCache`, queue
  watch changes in `PlexWatchSyncQueue`, and keep a `PlexStoredSession` in `PlexKeychainCredentialStore`.

## HTTP API map

One row per Plex HTTP call the module makes; `{…}` is an ID or a value you pass. Every call sends the
`X-Plex-Client-Identifier`/`-Product`/`-Version`/`-Platform` identity headers, and `X-Plex-Token` when authenticated.
**Test** links go to the test that asserts the exact request (method, path, query) and decodes the sample.

### Account (plex.tv)

`PlexAccountService` talks to plex.tv; account calls carry the **account** token.

| Method | Path | Swift API | Sample | Test |
| --- | --- | --- | --- | --- |
| POST | `https://plex.tv/api/v2/pins?strong=true` | [`PlexAccountService.createPIN()`](PlexAccountService.swift#L32) | [JSON](#sample-create-pin) | [createsStrongPINWithStableClientIdentity](../../Tests/Plex_Shared_Backend_Tests/PlexAccountTests.swift#L6) |
| GET | `https://plex.tv/api/v2/pins/{id}` | [`PlexAccountService.pin(id:)`](PlexAccountService.swift#L39) | [JSON](#sample-check-pin) | [pollsPendingAndClaimedPINs](../../Tests/Plex_Shared_Backend_Tests/PlexAccountTests.swift#L21) |
| browser | `https://app.plex.tv/auth#?clientID=…&code=…&context[device][product]=…` | [`PlexAccountService.authorizationURL(code:)`](PlexAccountService.swift#L52) | opened in a browser | [encodesBrowserAuthorizationInFragment](../../Tests/Plex_Shared_Backend_Tests/PlexAccountTests.swift#L38) |
| GET | `https://plex.tv/api/v2/resources?includeHttps=1&includeRelay=1&includeIPv6=1` | [`PlexAccountService.servers(accountToken:)`](PlexAccountService.swift#L74) | [JSON](#sample-resources) | [resources](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L55) |
| GET | `https://clients.plex.tv/api/v2/user` | [`PlexAccountService.user(accountToken:)`](PlexAccountService.swift#L82) | [JSON](#sample-user) | [user](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L72) |
| GET | `https://clients.plex.tv/api/v2/home/users` | [`PlexAccountService.homeUsers(accountToken:)`](PlexAccountService.swift#L87) | [JSON](#sample-home-users) | [homeUsers](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L81) |
| POST | `https://clients.plex.tv/api/v2/home/users/{uuid}/switch?pin=…` | [`PlexAccountService.switchUser(uuid:pin:accountToken:)`](PlexAccountService.swift#L95) | [JSON](#sample-switch-user) | [accountProfilesNormalizeScalarsAndSwitchThroughClientsAPI](../../Tests/Plex_Shared_Backend_Tests/PlexExtendedAPITests.swift#L66) |

### Discovery and connection

From here on, paths are relative to the server and carry the **server** token.

| Method | Path | Swift API | Sample | Test |
| --- | --- | --- | --- | --- |
| GET | `/identity` | [`PlexServerConnector.connect(to:identity:allowHTTP:)`](PlexServerConnector.swift#L188)<br>[`PlexServerConnecting.connectBest(among:identity:content:allowHTTP:gracePeriod:)`](PlexServerConnector.swift#L116)<br>[`PlexAPIService.machineIdentifier()`](PlexAPIService.swift#L168) | [JSON](#sample-identity) | [connectorProbesIdentityThenSections](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L110)<br>[skipsDeadExpiredAndContentlessServersAndChoosesTheWorkingMovieServer](../../Tests/Plex_Shared_Backend_Tests/PlexServerConnectorTests.swift#L148)<br>[identity](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L96) |
| GET | `/library/sections` | [`PlexServerConnector.connect(to:identity:allowHTTP:)`](PlexServerConnector.swift#L188)<br>[`PlexServerConnecting.connectBest(among:identity:content:allowHTTP:gracePeriod:)`](PlexServerConnector.swift#L116)<br>[`PlexAPIService.libraries()`](PlexAPIService.swift#L72) | [JSON](#sample-library-sections) | [connectorProbesIdentityThenSections](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L110)<br>[skipsDeadExpiredAndContentlessServersAndChoosesTheWorkingMovieServer](../../Tests/Plex_Shared_Backend_Tests/PlexServerConnectorTests.swift#L148)<br>[librarySections](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L101) |

### Browse

Pageable calls add `X-Plex-Container-Start` and `X-Plex-Container-Size` from `PlexPagination`.

| Method | Path | Swift API | Sample | Test |
| --- | --- | --- | --- | --- |
| GET | `/library/sections/{id}/all?type=…&sort=…&{filter}=…` | [`PlexAPIService.items(sectionID:page:query:)`](PlexAPIService.swift#L77) | [JSON](#sample-library-items) | [libraryItems](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L123) |
| GET | `/library/shared/all` | [`PlexAPIService.items(sectionID: "shared")`](PlexAPIService.swift#L77) | [JSON](#sample-library-items) | [libraryItems](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L123) |
| GET | `/library/metadata/{id}?includeMarkers=1&includeChapters=1&checkFiles=1&includeStreams=1&includeOnDeck=1` | [`PlexAPIService.metadata(ratingKey:)`](PlexAPIService.swift#L84) | [JSON](#sample-metadata) | [metadata](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L138) |
| GET | `/library/metadata/{id}/children?includeStreams=1` | [`PlexAPIService.children(ratingKey:page:)`](PlexAPIService.swift#L91) | [JSON](#sample-children) | [children](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L147) |
| GET | `/library/metadata/{id}/grandchildren?includeStreams=1` | [`PlexAPIService.grandchildren(ratingKey:page:)`](PlexAPIService.swift#L96) | [JSON](#sample-grandchildren) | [grandchildren](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L159) |
| GET | `/library/search?query=…&searchTypes=movies,tv&includeCollections=1` | [`PlexAPIService.search(query:page:)`](PlexAPIService.swift#L101) | [JSON](#sample-search) | [search](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L170) |
| GET | `/library/recentlyAdded` | [`PlexAPIService.recentlyAdded(page:)`](PlexAPIService.swift#L106) | [JSON](#sample-recently-added) | [recentlyAdded](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L180) |
| GET | `/library/metadata/{id}/extras` | [`PlexAPIService.extras(ratingKey:)`](PlexAPIService.swift#L111) | [JSON](#sample-extras) | [extras](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L190) |
| GET | `/library/sections/{id}/filters` | [`PlexAPIService.filters(sectionID:)`](PlexAPIService.swift#L116) | [JSON](#sample-filters) | [filters](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L199) |
| GET | `/library/sections/{id}/sorts` | [`PlexAPIService.sorts(sectionID:)`](PlexAPIService.swift#L121) | [JSON](#sample-sorts) | [sorts](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L209) |
| GET | `/library/sections/{id}/firstCharacter?type=…` | [`PlexAPIService.firstCharacters(sectionID:query:)`](PlexAPIService.swift#L126) | [JSON](#sample-first-characters) | [firstCharacters](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L219) |
| GET | `/library/sections/{id}/folder?includeCollections=0` | [`PlexAPIService.folders(sectionID:)`](PlexAPIService.swift#L134) | [JSON](#sample-folders) | [folders](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L227) |
| GET | `/library/people/{id}/media` | [`PlexAPIService.personMedia(personID:page:)`](PlexAPIService.swift#L140) | [JSON](#sample-person-media) | [personMedia](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L235) |
| GET | `{key}` (any key the server returns) | [`PlexAPIService.container(key:page:)`](PlexAPIService.swift#L146) | [JSON](#sample-server-key) | [serverKey](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L243) |

### Hubs

Shelves without items are dropped; follow `PlexHub.key` with `container(key:page:)` for the full list.

| Method | Path | Swift API | Sample | Test |
| --- | --- | --- | --- | --- |
| GET | `/hubs?count=…&includeGuids=1` | [`PlexAPIService.homeHubs(count:)`](PlexHubs.swift#L17) | [JSON](#sample-home-hubs) | [homeHubs](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L253) |
| GET | `/hubs?count=…&includeGuids=1&identifier=home.continue,home.ondeck` | [`PlexAPIService.continueWatching(count:)`](PlexHubs.swift#L22) | [JSON](#sample-continue-watching) | [continueWatching](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L265) |
| GET | `/hubs/sections/{id}?count=…&includeGuids=1` | [`PlexAPIService.sectionHubs(sectionID:count:)`](PlexHubs.swift#L38) | [JSON](#sample-section-hubs) | [sectionHubs](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L277) |
| GET | `/hubs/metadata/{id}/related?count=…` | [`PlexAPIService.relatedHubs(ratingKey:count:)`](PlexHubs.swift#L43) | [JSON](#sample-related-hubs) | [relatedHubs](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L287) |

### Watch state

`PlexWatchSyncQueue.sync(serverID:using:)` replays offline changes through these calls.

| Method | Path | Swift API | Sample | Test |
| --- | --- | --- | --- | --- |
| GET | `/:/scrobble?key={id}&identifier=com.plexapp.plugins.library` | [`PlexAPIService.markWatched(ratingKey:)`](PlexWatchState.swift#L31) | empty body | [watchStateMutations](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L8) |
| GET | `/:/unscrobble?key={id}&identifier=com.plexapp.plugins.library` | [`PlexAPIService.markUnwatched(ratingKey:)`](PlexWatchState.swift#L36) | empty body | [watchStateMutations](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L8) |
| POST | `/:/timeline?ratingKey=…&key=…&state=…&time=…&duration=…[&offline=1&updated=…]` | [`PlexAPIService.reportTimeline(ratingKey:state:time:duration:recordedAt:)`](PlexWatchState.swift#L42) | empty body | [watchStateMutations](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L8) |
| PUT | `/:/rate?key={id}&identifier=com.plexapp.plugins.library&rating=…` | [`PlexAPIService.rate(ratingKey:rating:)`](PlexWatchState.swift#L58) | empty body | [watchStateMutations](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L8) |
| PUT | `/actions/removeFromContinueWatching?ratingKey={id}` | [`PlexAPIService.removeFromContinueWatching(ratingKey:)`](PlexWatchState.swift#L66) | empty body | [watchStateMutations](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L8) |

### Collections

`server://` URIs use the configured machine identifier, or fetch `/identity` once when there is none.

| Method | Path | Swift API | Sample | Test |
| --- | --- | --- | --- | --- |
| GET | `/library/sections/{id}/collections` | [`PlexAPIService.collections(sectionID:page:)`](PlexCollections.swift#L96) | [JSON](#sample-collections) | [collections](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L27) |
| GET | `/library/collections/{id}/children` | [`PlexAPIService.collectionItems(collectionID:page:)`](PlexCollections.swift#L102) | [JSON](#sample-collection-items) | [collectionItems](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L37) |
| POST | `/library/collections?type=…&title=…&smart=0&sectionId=…&uri=server://…` | [`PlexAPIService.createCollection(sectionID:title:type:ratingKeys:)`](PlexCollections.swift#L107) | [JSON](#sample-create-collection) | [createCollection](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L46) |
| PUT | `/library/collections/{id}/items?uri=server://…` | [`PlexAPIService.addToCollection(collectionID:ratingKeys:)`](PlexCollections.swift#L119) | empty body | [listMutations](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L96) |
| DELETE | `/library/collections/{id}/items/{ratingKey}` | [`PlexAPIService.removeFromCollection(collectionID:ratingKey:)`](PlexCollections.swift#L126) | empty body | [playlistEntriesAreRemovedAndMovedByPlaylistItemID](../../Tests/Plex_Shared_Backend_Tests/PlexFeatureAPITests.swift#L113) |
| DELETE | `/library/collections/{id}` | [`PlexAPIService.deleteCollection(collectionID:)`](PlexCollections.swift#L131) | empty body | [listMutations](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L96) |

### Playlists

| Method | Path | Swift API | Sample | Test |
| --- | --- | --- | --- | --- |
| GET | `/playlists?playlistType=video` | [`PlexAPIService.playlists(type:page:)`](PlexCollections.swift#L140) | [JSON](#sample-playlists) | [playlists](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L58) |
| GET | `/playlists/{id}` | [`PlexAPIService.playlist(id:)`](PlexCollections.swift#L146) | [JSON](#sample-playlist) | [playlist](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L68) |
| GET | `/playlists/{id}/items` | [`PlexAPIService.playlistItems(id:page:)`](PlexCollections.swift#L153) | [JSON](#sample-playlist-items) | [playlistItems](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L77) |
| POST | `/playlists?type=video&title=…&smart=0&uri=server://…` | [`PlexAPIService.createPlaylist(title:ratingKeys:)`](PlexCollections.swift#L158) | [JSON](#sample-create-playlist) | [createPlaylist](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L87) |
| PUT | `/playlists/{id}/items?uri=server://…` | [`PlexAPIService.addToPlaylist(id:ratingKeys:)`](PlexCollections.swift#L168) | empty body | [listMutations](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L96) |
| DELETE | `/playlists/{id}/items/{playlistItemID}` | [`PlexAPIService.removeFromPlaylist(id:playlistItemID:)`](PlexCollections.swift#L175) | empty body | [playlistEntriesAreRemovedAndMovedByPlaylistItemID](../../Tests/Plex_Shared_Backend_Tests/PlexFeatureAPITests.swift#L113) |
| PUT | `/playlists/{id}/items/{playlistItemID}/move?after=…` | [`PlexAPIService.movePlaylistItem(id:playlistItemID:afterPlaylistItemID:)`](PlexCollections.swift#L180) | empty body | [playlistEntriesAreRemovedAndMovedByPlaylistItemID](../../Tests/Plex_Shared_Backend_Tests/PlexFeatureAPITests.swift#L113) |
| DELETE | `/playlists/{id}` | [`PlexAPIService.deletePlaylist(id:)`](PlexCollections.swift#L186) | empty body | [playlistEntriesAreRemovedAndMovedByPlaylistItemID](../../Tests/Plex_Shared_Backend_Tests/PlexFeatureAPITests.swift#L113) |

### Play queues

| Method | Path | Swift API | Sample | Test |
| --- | --- | --- | --- | --- |
| POST | `/playQueues?type=video&shuffle=…&repeat=0&continuous=…&uri=server://…\|playlistID=…[&key=…]` | [`PlexAPIService.createPlayQueue(source:shuffle:startingRatingKey:)`](PlexCollections.swift#L195) | [JSON](#sample-play-queue) | [playQueues](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L111) |
| GET | `/playQueues/{id}?window=…&includeBefore=1&includeAfter=1` | [`PlexAPIService.playQueue(id:window:)`](PlexCollections.swift#L215) | [JSON](#sample-play-queue) | [playQueues](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L111) |

### Media and playback

Request builders return an authenticated `URLRequest` for your player or `URLSession`; never log its headers.

| Method | Path | Swift API | Sample | Test |
| --- | --- | --- | --- | --- |
| GET | `/photo/:/transcode?width=…&height=…&minSize=1&upscale=1&url={path}`, or `{path}` unsized | [`PlexAPIService.imageRequest(path:width:height:)`](PlexMedia.swift#L104)<br>[`PlexAPIService.imageData(path:width:height:)`](PlexMedia.swift#L115) | image bytes | [mediaRequests](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L130) |
| GET | `{Part.key}` | [`PlexAPIService.directPlayRequest(part:)`](PlexMedia.swift#L120) | original file | [mediaRequests](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L130) |
| GET | `/video/:/transcode/universal/start.m3u8?path=…&protocol=hls&…` | [`PlexAPIService.streamRequest(_:)`](PlexMedia.swift#L127) | HLS playlist | [mediaRequests](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L130)<br>[streamRequestEncodesTheProfileAndKeepsTheTokenInHeaders](../../Tests/Plex_Shared_Backend_Tests/PlexFeatureAPITests.swift#L165) |
| GET | `/video/:/transcode/universal/stop?session=…` | [`PlexAPIService.stopStream(session:)`](PlexMedia.swift#L154) | empty body | [mediaMutations](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L144) |
| GET | `/library/parts/{id}/indexes/sd` | [`PlexAPIService.previewThumbnailsRequest(partID:)`](PlexMedia.swift#L159) | BIF bytes | [mediaRequests](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L130) |
| PUT | `/library/parts/{id}?audioStreamID=…&subtitleStreamID=…&allParts=1` | [`PlexAPIService.selectStreams(partID:audioStreamID:subtitleStreamID:)`](PlexMedia.swift#L164) | empty body | [mediaMutations](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L144) |
| GET | `/library/metadata/{id}/subtitles?language=…&hearingImpaired=0&forced=0` | [`PlexAPIService.searchSubtitles(ratingKey:language:)`](PlexMedia.swift#L172) | [JSON](#sample-subtitle-search) | [subtitles](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L155) |
| PUT | `/library/metadata/{id}/subtitles?key=…&codec=…&language=…&hearingImpaired=…&forced=…&providerTitle=…` | [`PlexAPIService.downloadSubtitle(ratingKey:result:)`](PlexMedia.swift#L181) | empty body | [subtitles](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L155) |

### Downloads

The plan only builds requests; your app owns transfers, storage and resume.

| Method | Path | Swift API | Sample | Test |
| --- | --- | --- | --- | --- |
| GET | `/library/metadata/{id}?…`, then your transfer code sends `{Part.key}` and `{Stream.key}.{ext}?encoding=utf-8` | [`PlexAPIService.downloadPlan(ratingKey:mediaIndex:selection:)`](PlexAPIService.swift#L156)<br>[`PlexDownloadPlanner.plan(for:mediaIndex:selection:)`](PlexDownloadPlan.swift#L62) | [JSON](#sample-metadata) | [downloadPlan](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests.swift#L299)<br>[preservesAllPartsByDefaultAndSupportsPlezySelection](../../Tests/Plex_Shared_Backend_Tests/PlexDownloadTests.swift#L10) |

### Server and admin

Most mutations need the server owner or an admin. `recordingRules()` and `scheduledRecordings()` return the raw
container, which types only `Directory`, `Metadata` and `Hub` lists; read other entries, such as the `MediaSubscription`
ones in the sample, with `execute(path:)`.

| Method | Path | Swift API | Sample | Test |
| --- | --- | --- | --- | --- |
| GET | `/` | [`PlexAPIService.serverInfo()`](PlexServerAdmin.swift#L152) | [JSON](#sample-server-info) | [serverInfo](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L172) |
| GET | `/:/prefs` | [`PlexAPIService.serverPreferences()`](PlexServerAdmin.swift#L155)<br>[`PlexAPIService.watchedThreshold()`](PlexWatchState.swift#L71) | [JSON](#sample-prefs) | [serverPreferences](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L181) |
| GET | `/activities` | [`PlexAPIService.activities()`](PlexServerAdmin.swift#L158) | [JSON](#sample-activities) | [activities](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L193) |
| DELETE | `/activities/{uuid}` | [`PlexAPIService.cancelActivity(uuid:)`](PlexServerAdmin.swift#L161) | empty body | [adminMutations](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L203) |
| GET | `/library/sections/{id}/refresh[?force=1]` | [`PlexAPIService.scanLibrary(sectionID:force:)`](PlexServerAdmin.swift#L166) | empty body | [adminMutations](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L203) |
| PUT | `/library/sections/{id}/analyze` | [`PlexAPIService.analyzeLibrary(sectionID:)`](PlexServerAdmin.swift#L171) | empty body | [adminMutations](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L203) |
| PUT | `/library/sections/{id}/emptyTrash` | [`PlexAPIService.emptyTrash(sectionID:)`](PlexServerAdmin.swift#L176) | empty body | [adminMutations](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L203) |
| PUT | `/library/metadata/{id}/refresh` | [`PlexAPIService.refreshMetadata(ratingKey:)`](PlexServerAdmin.swift#L181) | empty body | [adminMutations](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L203) |
| DELETE | `/library/metadata/{id}` | [`PlexAPIService.deleteItem(ratingKey:)`](PlexServerAdmin.swift#L186) | empty body | [adminMutations](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L203) |
| GET | `/livetv/dvrs` | [`PlexAPIService.dvrs()`](PlexServerAdmin.swift#L191) | [JSON](#sample-dvrs) | [dvrs](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L224) |
| GET | `/media/subscriptions?includeGrabs=1&includeStorage=1` | [`PlexAPIService.recordingRules()`](PlexServerAdmin.swift#L194) | [JSON](#sample-recording-rules) | [recordingRules](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L232) |
| GET | `/media/subscriptions/scheduled` | [`PlexAPIService.scheduledRecordings()`](PlexServerAdmin.swift#L199) | [JSON](#sample-scheduled-recordings) | [scheduledRecordings](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L241) |

### Notifications

| Method | Path | Swift API | Sample | Test |
| --- | --- | --- | --- | --- |
| GET | `/:/eventsource/notifications` with `Accept: text/event-stream` | [`PlexAPIService.notificationsRequest()`](PlexServerAdmin.swift#L204)<br>[`PlexEventSource.events(for:)`](PlexNotifications.swift#L19) | [SSE](#sample-notifications) | [notifications](../../Tests/Plex_Shared_Backend_Tests/PlexAPISampleTests+Server.swift#L253)<br>[serverSentEventsAreGroupedByBlankLines](../../Tests/Plex_Shared_Backend_Tests/PlexFeatureAPITests.swift#L319) |

### Anything else

Same token, proxy-prefix and redirect rules as the typed calls.

| Method | Path | Swift API | Sample | Test |
| --- | --- | --- | --- | --- |
| any | `{path}` | [`PlexAPIService.request(_:)`](PlexAPIService.swift#L57)<br>[`PlexAPIService.execute(path:method:query:body:contentType:)`](PlexServerRequest.swift#L58)<br>[`PlexAPIService.makeRequest(path:method:query:body:contentType:)`](PlexServerRequest.swift#L72)<br>[`PlexAPIService.resourceRequest(path:)`](PlexServerRequest.swift#L85) | raw `PlexHTTPResult` | [rawMutationsAcceptEmptySuccessfulResponses](../../Tests/Plex_Shared_Backend_Tests/PlexExtendedAPITests.swift#L6) |

## Sample responses

Synthetic fixtures, copied from the tests and pretty-printed. Change them in both places together.

<a id="sample-create-pin"></a>
<details><summary><code>POST https://plex.tv/api/v2/pins?strong=true</code></summary>

```json
{"id": 123, "code": "pin-code", "expiresIn": "1800", "authToken": null}
```

</details>

<a id="sample-check-pin"></a>
<details><summary><code>GET https://plex.tv/api/v2/pins/{id}</code></summary>

```json
{"id": "123", "code": "pin-code", "authToken": "account-token"}
```

</details>

<a id="sample-resources"></a>
<details><summary><code>GET https://plex.tv/api/v2/resources</code></summary>

```json
[
  {"name": "Living Room TV", "clientIdentifier": "player-1", "provides": "player,pubsub-player"},
  {
    "name": "Home Server",
    "clientIdentifier": "machine",
    "provides": "server",
    "owned": true,
    "accessToken": "server-token",
    "connections": [
      {"protocol": "https", "uri": "https://local.media.example:32400", "local": true, "relay": false, "IPv6": false},
      {"protocol": "https", "uri": "https://relay.media.example:8443", "local": false, "relay": true, "IPv6": false}
    ]
  }
]
```

</details>

<a id="sample-user"></a>
<details><summary><code>GET https://clients.plex.tv/api/v2/user</code></summary>

```json
{"id": 1001, "uuid": "owner-uuid", "username": "owner", "title": "Owner", "protected": false}
```

</details>

<a id="sample-home-users"></a>
<details><summary><code>GET https://clients.plex.tv/api/v2/home/users</code></summary>

```json
{
  "id": 1,
  "name": "Sample Home",
  "users": [
    {"id": 1001, "uuid": "owner-uuid", "title": "Owner", "admin": true, "protected": false},
    {"id": 1002, "uuid": "kid-uuid", "title": "Kid", "admin": false, "protected": true}
  ]
}
```

</details>

<a id="sample-switch-user"></a>
<details><summary><code>POST https://clients.plex.tv/api/v2/home/users/{uuid}/switch</code></summary>

```json
{"authToken": "profile-token"}
```

</details>

<a id="sample-identity"></a>
<details><summary><code>GET /identity</code></summary>

```json
{"MediaContainer": {"size": 0, "claimed": true, "machineIdentifier": "machine", "version": "1.40.0.0000"}}
```

</details>

<a id="sample-library-sections"></a>
<details><summary><code>GET /library/sections</code></summary>

```json
{
  "MediaContainer": {
    "size": 2,
    "allowSync": false,
    "title1": "Plex Library",
    "Directory": [
      {"key": "1", "type": "movie", "title": "Movies", "uuid": "section-uuid-1", "agent": "tv.plex.agents.movie", "thumb": "/:/resources/movie.png"},
      {"key": "2", "type": "show", "title": "TV Shows", "uuid": "section-uuid-2", "agent": "tv.plex.agents.series"}
    ]
  }
}
```

</details>

<a id="sample-library-items"></a>
<details><summary><code>GET /library/sections/{id}/all</code></summary>

```json
{
  "MediaContainer": {
    "size": 2,
    "totalSize": 40,
    "offset": 0,
    "title1": "Movies",
    "librarySectionID": 1,
    "Metadata": [
      {
        "ratingKey": "42",
        "key": "/library/metadata/42",
        "guid": "plex://movie/sample-42",
        "type": "movie",
        "title": "Sample Movie",
        "year": 2024,
        "duration": 7200000,
        "viewOffset": 600000,
        "addedAt": 1700000000,
        "thumb": "/library/metadata/42/thumb/1700000000"
      },
      {"ratingKey": "43", "key": "/library/metadata/43", "type": "movie", "title": "Another Movie", "year": 2023, "viewCount": 1}
    ]
  }
}
```

</details>

<a id="sample-metadata"></a>
<details><summary><code>GET /library/metadata/{id}</code></summary>

```json
{
  "MediaContainer": {
    "size": 1,
    "librarySectionID": 1,
    "librarySectionTitle": "Movies",
    "Metadata": [
      {
        "ratingKey": "42",
        "key": "/library/metadata/42",
        "guid": "plex://movie/sample-42",
        "type": "movie",
        "title": "Sample Movie",
        "summary": "A synthetic movie.",
        "year": 2024,
        "contentRating": "PG-13",
        "duration": 7200000,
        "viewOffset": 600000,
        "Media": [
          {
            "id": 1,
            "container": "mkv",
            "videoCodec": "hevc",
            "audioCodec": "aac",
            "videoResolution": "4k",
            "width": 3840,
            "height": 2160,
            "bitrate": 20000,
            "audioChannels": 6,
            "duration": 7200000,
            "Part": [
              {
                "id": 7,
                "key": "/library/parts/7/1700000000/file.mkv",
                "file": "/data/movies/Sample Movie (2024).mkv",
                "container": "mkv",
                "size": 18000000000,
                "duration": 7200000,
                "exists": true,
                "accessible": true,
                "Stream": [
                  {"id": 100, "streamType": 1, "codec": "hevc", "displayTitle": "4K (HEVC Main 10)"},
                  {"id": 101, "streamType": 2, "codec": "aac", "language": "English", "languageCode": "eng", "displayTitle": "English (AAC 5.1)", "selected": true},
                  {"id": 102, "streamType": 3, "key": "/library/streams/102", "codec": "srt", "language": "English", "languageCode": "eng", "displayTitle": "English (SRT External)"}
                ]
              }
            ]
          }
        ],
        "Genre": [{"id": 5, "tag": "Drama"}],
        "Director": [{"id": 6, "tag": "Sample Director"}],
        "Role": [{"id": 8, "tag": "Sample Actor", "role": "Lead"}],
        "Marker": [{"type": "intro", "startTimeOffset": 0, "endTimeOffset": 30000}]
      }
    ]
  }
}
```

</details>

<a id="sample-children"></a>
<details><summary><code>GET /library/metadata/{id}/children</code></summary>

```json
{
  "MediaContainer": {
    "size": 2,
    "key": "10",
    "parentTitle": "Sample Show",
    "Metadata": [
      {
        "ratingKey": "11",
        "key": "/library/metadata/11/children",
        "parentRatingKey": "10",
        "type": "season",
        "title": "Season 1",
        "index": 1,
        "parentTitle": "Sample Show",
        "leafCount": 8,
        "viewedLeafCount": 8
      },
      {
        "ratingKey": "12",
        "key": "/library/metadata/12/children",
        "parentRatingKey": "10",
        "type": "season",
        "title": "Season 2",
        "index": 2,
        "parentTitle": "Sample Show",
        "leafCount": 8,
        "viewedLeafCount": 3
      }
    ]
  }
}
```

</details>

<a id="sample-grandchildren"></a>
<details><summary><code>GET /library/metadata/{id}/grandchildren</code></summary>

```json
{
  "MediaContainer": {
    "size": 1,
    "totalSize": 16,
    "offset": 0,
    "Metadata": [
      {
        "ratingKey": "101",
        "key": "/library/metadata/101",
        "parentRatingKey": "11",
        "grandparentRatingKey": "10",
        "type": "episode",
        "title": "Pilot",
        "grandparentTitle": "Sample Show",
        "parentIndex": 1,
        "index": 1,
        "duration": 2700000,
        "viewCount": 1
      }
    ]
  }
}
```

</details>

<a id="sample-search"></a>
<details><summary><code>GET /library/search</code></summary>

```json
{
  "MediaContainer": {
    "size": 2,
    "SearchResult": [
      {"score": 0.92, "Metadata": {"ratingKey": "42", "type": "movie", "title": "Sample Movie", "year": 2024}},
      {"score": 0.81, "Metadata": {"ratingKey": "10", "type": "show", "title": "Sample Show", "year": 2020}}
    ]
  }
}
```

</details>

<a id="sample-recently-added"></a>
<details><summary><code>GET /library/recentlyAdded</code></summary>

```json
{
  "MediaContainer": {
    "size": 1,
    "Metadata": [
      {"ratingKey": "101", "type": "episode", "title": "Pilot", "grandparentTitle": "Sample Show", "grandparentThumb": "/library/metadata/10/thumb/1700000000", "addedAt": 1700000000}
    ]
  }
}
```

</details>

<a id="sample-extras"></a>
<details><summary><code>GET /library/metadata/{id}/extras</code></summary>

```json
{
  "MediaContainer": {
    "size": 1,
    "Metadata": [
      {"ratingKey": "900", "key": "/library/metadata/900", "type": "clip", "subtype": "trailer", "title": "Official Trailer", "duration": 150000}
    ]
  }
}
```

</details>

<a id="sample-filters"></a>
<details><summary><code>GET /library/sections/{id}/filters</code></summary>

```json
{
  "MediaContainer": {
    "size": 2,
    "Directory": [
      {"filter": "genre", "filterType": "string", "key": "/library/sections/1/genre", "title": "Genre", "type": "filter"},
      {"filter": "unwatched", "filterType": "boolean", "key": "/library/sections/1/unwatched", "title": "Unplayed", "type": "filter"}
    ]
  }
}
```

</details>

<a id="sample-sorts"></a>
<details><summary><code>GET /library/sections/{id}/sorts</code></summary>

```json
{
  "MediaContainer": {
    "size": 2,
    "Directory": [
      {"key": "titleSort", "descKey": "titleSort:desc", "title": "Title", "defaultDirection": "asc"},
      {"key": "addedAt", "descKey": "addedAt:desc", "title": "Date Added", "defaultDirection": "desc"}
    ]
  }
}
```

</details>

<a id="sample-first-characters"></a>
<details><summary><code>GET /library/sections/{id}/firstCharacter</code></summary>

```json
{
  "MediaContainer": {
    "size": 2,
    "Directory": [{"key": "A", "title": "A", "size": 3}, {"key": "S", "title": "S", "size": 12}]
  }
}
```

</details>

<a id="sample-folders"></a>
<details><summary><code>GET /library/sections/{id}/folder</code></summary>

```json
{
  "MediaContainer": {
    "size": 1,
    "title1": "Movies",
    "Directory": [{"key": "/library/sections/1/folder?parent=200", "title": "Action"}]
  }
}
```

</details>

<a id="sample-person-media"></a>
<details><summary><code>GET /library/people/{id}/media</code></summary>

```json
{
  "MediaContainer": {
    "size": 1,
    "Metadata": [{"ratingKey": "42", "type": "movie", "title": "Sample Movie", "year": 2024}]
  }
}
```

</details>

<a id="sample-server-key"></a>
<details><summary><code>GET {key}, here a filter's /library/sections/1/genre</code></summary>

```json
{
  "MediaContainer": {
    "size": 2,
    "Directory": [{"key": "12", "title": "Drama"}, {"key": "13", "title": "Comedy"}]
  }
}
```

</details>

<a id="sample-home-hubs"></a>
<details><summary><code>GET /hubs</code></summary>

```json
{
  "MediaContainer": {
    "size": 2,
    "Hub": [
      {
        "hubIdentifier": "home.movies.recent",
        "key": "/hubs/home/recentlyAdded?type=1",
        "title": "Recently Added Movies",
        "type": "movie",
        "size": 1,
        "more": true,
        "Metadata": [{"ratingKey": "42", "type": "movie", "title": "Sample Movie"}]
      },
      {"hubIdentifier": "home.television.recent", "key": "/hubs/home/recentlyAdded?type=2", "title": "Recently Added TV", "type": "mixed", "size": 0, "more": false}
    ]
  }
}
```

</details>

<a id="sample-continue-watching"></a>
<details><summary><code>GET /hubs?identifier=home.continue,home.ondeck</code></summary>

```json
{
  "MediaContainer": {
    "size": 2,
    "Hub": [
      {
        "hubIdentifier": "home.continue",
        "title": "Continue Watching",
        "type": "mixed",
        "Metadata": [
          {"ratingKey": "42", "type": "movie", "title": "Sample Movie", "viewOffset": 600000, "duration": 7200000}
        ]
      },
      {
        "hubIdentifier": "home.ondeck",
        "title": "On Deck",
        "type": "mixed",
        "Metadata": [
          {"ratingKey": "102", "type": "episode", "title": "Episode 2", "grandparentRatingKey": "10", "grandparentTitle": "Sample Show"}
        ]
      }
    ]
  }
}
```

</details>

<a id="sample-section-hubs"></a>
<details><summary><code>GET /hubs/sections/{id}</code></summary>

```json
{
  "MediaContainer": {
    "size": 1,
    "Hub": [
      {
        "hubIdentifier": "movie.recentlyadded.1",
        "key": "/library/sections/1/recentlyAdded",
        "title": "Recently Added in Movies",
        "type": "movie",
        "more": true,
        "Metadata": [{"ratingKey": "42", "type": "movie", "title": "Sample Movie"}]
      }
    ]
  }
}
```

</details>

<a id="sample-related-hubs"></a>
<details><summary><code>GET /hubs/metadata/{id}/related</code></summary>

```json
{
  "MediaContainer": {
    "size": 1,
    "Hub": [
      {
        "hubIdentifier": "movie.similar",
        "key": "/library/metadata/42/similar",
        "title": "More Like This",
        "type": "movie",
        "Metadata": [{"ratingKey": "43", "type": "movie", "title": "Another Movie"}]
      }
    ]
  }
}
```

</details>

<a id="sample-collections"></a>
<details><summary><code>GET /library/sections/{id}/collections</code></summary>

```json
{
  "MediaContainer": {
    "size": 1,
    "Metadata": [
      {"ratingKey": "500", "key": "/library/collections/500/children", "type": "collection", "subtype": "movie", "title": "Sample Collection", "childCount": 2, "smart": false}
    ]
  }
}
```

</details>

<a id="sample-collection-items"></a>
<details><summary><code>GET /library/collections/{id}/children</code></summary>

```json
{
  "MediaContainer": {
    "size": 2,
    "Metadata": [
      {"ratingKey": "42", "type": "movie", "title": "Sample Movie"},
      {"ratingKey": "43", "type": "movie", "title": "Another Movie"}
    ]
  }
}
```

</details>

<a id="sample-create-collection"></a>
<details><summary><code>POST /library/collections</code></summary>

```json
{
  "MediaContainer": {
    "size": 1,
    "Metadata": [
      {"ratingKey": "501", "key": "/library/collections/501/children", "type": "collection", "subtype": "movie", "title": "Favorites", "childCount": 2, "smart": false}
    ]
  }
}
```

</details>

<a id="sample-playlists"></a>
<details><summary><code>GET /playlists</code></summary>

```json
{
  "MediaContainer": {
    "size": 1,
    "Metadata": [
      {
        "ratingKey": "600",
        "key": "/playlists/600/items",
        "type": "playlist",
        "title": "Weekend",
        "playlistType": "video",
        "smart": false,
        "leafCount": 2,
        "duration": 9900000,
        "composite": "/playlists/600/composite/1700000000"
      }
    ]
  }
}
```

</details>

<a id="sample-playlist"></a>
<details><summary><code>GET /playlists/{id}</code></summary>

```json
{
  "MediaContainer": {
    "size": 1,
    "Metadata": [
      {"ratingKey": "600", "type": "playlist", "title": "Weekend", "playlistType": "video", "smart": false, "leafCount": 2, "duration": 9900000}
    ]
  }
}
```

</details>

<a id="sample-playlist-items"></a>
<details><summary><code>GET /playlists/{id}/items</code></summary>

```json
{
  "MediaContainer": {
    "size": 2,
    "totalSize": 2,
    "Metadata": [
      {"ratingKey": "42", "playlistItemID": 9001, "type": "movie", "title": "Sample Movie"},
      {"ratingKey": "101", "playlistItemID": 9002, "type": "episode", "title": "Pilot", "grandparentTitle": "Sample Show"}
    ]
  }
}
```

</details>

<a id="sample-create-playlist"></a>
<details><summary><code>POST /playlists</code></summary>

```json
{
  "MediaContainer": {
    "size": 1,
    "Metadata": [
      {"ratingKey": "600", "type": "playlist", "title": "Weekend", "playlistType": "video", "smart": false, "leafCount": 2}
    ]
  }
}
```

</details>

<a id="sample-play-queue"></a>
<details><summary><code>POST /playQueues, GET /playQueues/{id}</code></summary>

```json
{
  "MediaContainer": {
    "size": 2,
    "playQueueID": 77,
    "playQueueVersion": 1,
    "playQueueSelectedItemID": 7001,
    "playQueueTotalCount": 2,
    "playQueueShuffled": false,
    "Metadata": [
      {"ratingKey": "101", "playQueueItemID": 7001, "type": "episode", "title": "Pilot"},
      {"ratingKey": "102", "playQueueItemID": 7002, "type": "episode", "title": "Episode 2"}
    ]
  }
}
```

</details>

<a id="sample-subtitle-search"></a>
<details><summary><code>GET /library/metadata/{id}/subtitles</code></summary>

```json
{
  "MediaContainer": {
    "size": 1,
    "Stream": [
      {
        "key": "/subtitles/provider/sample-1",
        "streamType": 3,
        "codec": "srt",
        "language": "English",
        "languageCode": "eng",
        "displayTitle": "English (SRT)",
        "providerTitle": "OpenSubtitles",
        "score": "92",
        "hearingImpaired": false,
        "forced": false
      }
    ]
  }
}
```

</details>

<a id="sample-server-info"></a>
<details><summary><code>GET /</code></summary>

```json
{
  "MediaContainer": {"size": 0, "friendlyName": "Home Server", "machineIdentifier": "machine", "version": "1.40.0.0000", "platform": "Linux", "transcoderVideo": true, "myPlex": true}
}
```

</details>

<a id="sample-prefs"></a>
<details><summary><code>GET /:/prefs</code></summary>

```json
{
  "MediaContainer": {
    "size": 2,
    "Setting": [
      {"id": "FriendlyName", "label": "Friendly name", "summary": "The server's display name.", "type": "text", "default": "", "value": "Home Server"},
      {"id": "LibraryVideoPlayedThreshold", "label": "Video played threshold", "type": "int", "default": 90, "value": 90}
    ]
  }
}
```

</details>

<a id="sample-activities"></a>
<details><summary><code>GET /activities</code></summary>

```json
{
  "MediaContainer": {
    "size": 1,
    "Activity": [
      {"uuid": "activity-1", "type": "library.update.section", "cancellable": true, "userID": 1, "title": "Scanning Movies", "subtitle": "Sample Movie", "progress": 40}
    ]
  }
}
```

</details>

<a id="sample-dvrs"></a>
<details><summary><code>GET /livetv/dvrs</code></summary>

```json
{
  "MediaContainer": {
    "size": 1,
    "Dvr": [
      {"key": "3", "uuid": "dvr-uuid", "title": "Antenna", "lineupTitle": "Sample Lineup", "language": "eng"}
    ]
  }
}
```

</details>

<a id="sample-recording-rules"></a>
<details><summary><code>GET /media/subscriptions</code></summary>

```json
{
  "MediaContainer": {
    "size": 1,
    "MediaSubscription": [
      {
        "key": "sub-1",
        "type": 2,
        "targetLibrarySectionID": 2,
        "title": "Sample Show",
        "Directory": {"ratingKey": "10", "type": "show", "title": "Sample Show"}
      }
    ]
  }
}
```

</details>

<a id="sample-scheduled-recordings"></a>
<details><summary><code>GET /media/subscriptions/scheduled</code></summary>

```json
{
  "MediaContainer": {
    "size": 1,
    "MediaGrabOperation": [
      {
        "mediaSubscriptionID": "sub-1",
        "status": "scheduled",
        "Metadata": {"ratingKey": "1003", "type": "episode", "title": "Episode 3", "grandparentTitle": "Sample Show"}
      }
    ]
  }
}
```

</details>

<a id="sample-notifications"></a>
<details><summary><code>GET /:/eventsource/notifications</code></summary>

```text
event: activity
data: {"ActivityNotification":{"event":"updated","uuid":"activity-1","Activity":{"uuid":"activity-1","type":"library.update.section","progress":40}}}

event: playing
data: {"PlaySessionStateNotification":{"sessionKey":"1","ratingKey":"42","state":"playing","viewOffset":600000}}
```

</details>
