# RSS_Shared_Backend

RSS 2.0 parsing and fetching (with the iTunes podcast fields), podcast episodes, and the episode-to-movie matcher.
Foundation only. `RSSFeedService` takes an `RSSHTTPTransport`, and features depend on `RSSFeedProviding`, so both can
be stubbed. Playback lives in `Podcast_Player`, views in `Podcast_Shared_UI`.

## Quick integration

```swift
import RSS_Shared_Backend

// The shared service keeps each feed for 30 minutes, so every movie page reuses one ~1 MB download.
let feed = try await RSSFeedService.shared.feed(at: PodcastFeed.ignMovieReviews)

// Every item with an audio enclosure, in feed order (newest first).
let episodes = feed.episodes

// "Superman Review" for "Superman", never "Superman & Lois Season 4 Review".
let review = PodcastReviewMatcher.review(of: movie.title, releasedOn: movie.releaseDate, in: episodes)
```

Rules that matter:

- **Exact titles only.** The matcher drops a trailing "Review" and ignores case, accents, punctuation and "&" versus
  "and", then needs the titles to be equal. When a title was reviewed twice (remakes), the episode published closest to
  the release date wins, or the newest one without a date.
- **RSS 2.0 only.** Atom and RSS 1.0 throw `RSSParserError.missingChannel`; HTML error pages throw `.malformedXML`.
- **Failures aren't cached.** A non-2xx answer throws `RSSFeedError.httpStatus` and the next call downloads again.
