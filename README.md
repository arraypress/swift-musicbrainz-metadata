# Swift MusicBrainz Metadata

A Swift library for looking up and searching music metadata via the [MusicBrainz](https://musicbrainz.org) web service — releases, artists, release groups, recordings, and labels.

Every endpoint is **keyless** (no API token). Results cross-reference cleanly with Discogs: with URL relations included, releases, artists, release groups, and labels expose a matching `discogsURL`, so a MusicBrainz lookup lines up directly with [`swift-discogs-metadata`](https://github.com/arraypress).

## Features

- 🎵 **Typed lookups** — release, artist, release group, recording, label by MBID
- 🔎 **Search** — releases, artists, or release groups; paginated with a total `count`
- 💿 **Rich releases** — artist credits, labels + catalogue numbers, and the full tracklist (media → tracks)
- 🔗 **Discogs cross-reference** — `discogsURL` parsed from URL relations on releases, artists, release groups, and labels
- 🔓 **Keyless** — no API token required
- 🍎 **Cross-platform** — macOS, iOS, tvOS, watchOS · Swift 6 · async/await
- 🛡️ **Typed error handling**

## API notes

- MusicBrainz **requires a descriptive `User-Agent`**; requests without one are rejected with `503`. A default identifying this library is provided and can be overridden in `Configuration` (or via the `MUSICBRAINZ_USER_AGENT` environment variable).
- The service **rate-limits to roughly one request per second** — pace your calls to avoid `MusicBrainzMetadataError.rateLimited`.
- MBIDs are UUIDs (e.g. `5b11f4ce-a62d-471e-81fc-a69a8278c7da`).

## Usage

```swift
import MusicBrainzMetadata

// Search
let results = try await MusicBrainzMetadata.search("nevermind AND artist:nirvana", type: .release)
print("\(results.count) matches")
for hit in results.results {
    print("[\(hit.score)] \(hit.artistName ?? "?") – \(hit.title) (\(hit.date ?? "?")) [\(hit.country ?? "?")]")
}

// Release lookup: tracklist + labels + Discogs cross-reference
let release = try await MusicBrainzMetadata.release("b35c70b3-15f1-4792-a3d1-31645bde4db8")
print("\(release.artistName) – \(release.title) (\(release.date ?? "?")) — \(release.trackCount) tracks")
for track in release.tracks {
    print("  \(track.number). \(track.title) \(track.lengthFormatted ?? "")")
}
print("Discogs: \(release.discogsURL ?? "—")")

// Artist lookup: aliases + Discogs cross-reference
let artist = try await MusicBrainzMetadata.artist("5b11f4ce-a62d-471e-81fc-a69a8278c7da")
print("\(artist.name) [\(artist.type ?? "?")] — \(artist.lifeSpan.begin ?? "?")–\(artist.lifeSpan.end ?? "")")
print("Discogs: \(artist.discogsURL ?? "—")")

// Release group (≈ Discogs master), recording, and label
let group = try await MusicBrainzMetadata.releaseGroup("1b022e01-4da6-387b-8658-8678046e4cef")
let recording = try await MusicBrainzMetadata.recording("5fb524f1-8cc8-4c04-a921-e34c0a911ea7")
let label = try await MusicBrainzMetadata.label("68803e28-86fe-4a95-985f-8e493795ab31")

// Custom User-Agent (recommended — identify your app + a contact URL)
let config = MusicBrainzMetadata.Configuration(userAgent: "MyApp/1.0 (https://example.com)")
let byConfig = try await MusicBrainzMetadata.artist("5b11f4ce-a62d-471e-81fc-a69a8278c7da", configuration: config)
```

## Models

| Type | Description |
|------|-------------|
| `MBRelease` | `id`, `title`, `disambiguation`, `artistCredits`, `date`, `country`, `barcode`, `status`, `packaging`, `labels`, `media`, `discogsURL` (+ `artistName`, `tracks`, `trackCount`) |
| `MBMedium` / `MBTrack` | `position`, `format`, `title`, `trackCount`, `tracks` · track `id`, `title`, `number`, `position`, `length` (+ `lengthFormatted`), `recordingID` |
| `MBLabelInfo` | `catalogNumber`, `labelID`, `labelName` |
| `MBArtist` | `id`, `name`, `sortName`, `disambiguation`, `type`, `country`, `gender`, `lifeSpan`, `aliases`, `discogsURL` |
| `MBLifeSpan` / `MBAlias` | `begin`, `end`, `ended` · alias `name`, `sortName`, `locale`, `type`, `primary` |
| `MBReleaseGroup` | `id`, `title`, `disambiguation`, `primaryType`, `secondaryTypes`, `firstReleaseDate`, `artistCredits`, `discogsURL` (+ `artistName`) |
| `MBRecording` | `id`, `title`, `disambiguation`, `length` (+ `lengthFormatted`), `firstReleaseDate`, `video`, `artistCredits`, `discogsURL` (+ `artistName`) |
| `MBLabel` | `id`, `name`, `sortName`, `disambiguation`, `type`, `country`, `labelCode`, `area`, `lifeSpan`, `discogsURL` |
| `MBArtistCredit` | `name`, `joinPhrase`, `artistID`, `artistName`, `sortName`, `disambiguation` (+ `combined(_:)`) |
| `MBSearchResults` / `MBSearchResult` | Paginated hits with total `count`, `offset`, `hasMore` · result `id`, `type`, `score`, `title`, `artistName`, `sortName`, `date`, `country`, `primaryType` |
| `MusicBrainzMetadataError` | Typed errors with `errorDescription` |

## Testing

```bash
swift test                          # offline unit tests (fixtures)
MUSICBRAINZ_LIVE_TESTS=1 swift test # + live tests (real search + lookups, paced ~1 req/sec)
```

Set `MUSICBRAINZ_PRINT=1` alongside the live tests to print the resolved results.

## License

MIT

## Author

David Sherlock
