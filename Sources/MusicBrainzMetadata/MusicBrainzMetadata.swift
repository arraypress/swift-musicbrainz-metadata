//
//  MusicBrainzMetadata.swift
//  MusicBrainzMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Look up and search music metadata via the **keyless** MusicBrainz web service —
/// releases, artists, release groups, recordings, and labels.
///
/// Every endpoint used here is free and needs **no API key**. Results carry
/// cross-references back to Discogs: with URL relations included, ``MBRelease``,
/// ``MBArtist``, ``MBReleaseGroup`` and ``MBLabel`` expose a matching
/// `discogsURL`, so a MusicBrainz lookup lines up directly with `swift-discogs-metadata`.
///
/// ## API notes
///
/// - MusicBrainz **requires a descriptive `User-Agent`**; requests without one are
///   rejected with `503`. A default identifying this library is provided and can be
///   overridden in ``Configuration`` (or via the `MUSICBRAINZ_USER_AGENT` environment
///   variable).
/// - The service **rate-limits to roughly one request per second**. Pace your calls
///   (add a small delay between requests) to avoid ``MusicBrainzMetadataError/rateLimited``.
/// - MBIDs are UUIDs (e.g. `"5b11f4ce-a62d-471e-81fc-a69a8278c7da"`).
///
/// ## Quick Start
///
/// ```swift
/// import MusicBrainzMetadata
///
/// // Search
/// let results = try await MusicBrainzMetadata.search("nevermind AND artist:nirvana", type: .release)
/// print("\(results.count) matches")
/// for hit in results.results {
///     print("[\(hit.score)] \(hit.artistName ?? "?") – \(hit.title) (\(hit.date ?? "?"))")
/// }
///
/// // Lookup a release (tracklist + labels + Discogs cross-reference)
/// let release = try await MusicBrainzMetadata.release("b35c70b3-15f1-4792-a3d1-31645bde4db8")
/// print("\(release.artistName) – \(release.title): \(release.trackCount) tracks")
/// print("Discogs: \(release.discogsURL ?? "—")")
///
/// // Lookup an artist (aliases + Discogs cross-reference)
/// let artist = try await MusicBrainzMetadata.artist("5b11f4ce-a62d-471e-81fc-a69a8278c7da")
/// print("\(artist.name) [\(artist.type ?? "?")] — Discogs: \(artist.discogsURL ?? "—")")
/// ```
public enum MusicBrainzMetadata {

    // MARK: - Configuration

    /// Options for talking to the MusicBrainz web service.
    public struct Configuration: Sendable {

        /// The `User-Agent` sent with every request. MusicBrainz **requires** a
        /// descriptive one that identifies your application (and ideally a contact
        /// URL); the default identifies this library.
        public var userAgent: String

        /// How many times to try again after a 503.
        ///
        /// MusicBrainz meters against a bucket shared by everyone — the
        /// `x-ratelimit-remaining` header rises and falls with other people's
        /// traffic, not just yours — so a 503 arrives regardless of how well a
        /// single client paces itself. Retrying is the difference between a
        /// tool that works and one that fails a few times an hour for reasons
        /// its caller cannot see or influence.
        ///
        /// Set to zero to fail on the first 503.
        public var retryLimit: Int

        public init(
            userAgent: String = "swift-musicbrainz-metadata/1.0 (https://github.com/arraypress)",
            retryLimit: Int = 2
        ) {
            self.userAgent = userAgent
            self.retryLimit = retryLimit
        }

        /// Reads `MUSICBRAINZ_USER_AGENT` from the environment, falling back to the
        /// library default when unset.
        public static var `default`: Configuration {
            let env = ProcessInfo.processInfo.environment
            if let userAgent = env["MUSICBRAINZ_USER_AGENT"], !userAgent.isEmpty {
                return Configuration(userAgent: userAgent)
            }
            return Configuration()
        }
    }

    // MARK: - Search

    /// Searches MusicBrainz for releases, artists, or release groups.
    ///
    /// The `query` is a Lucene-style query string, e.g.
    /// `"nevermind AND artist:nirvana"` or simply `"nirvana"`.
    ///
    /// - Parameters:
    ///   - query: The search query.
    ///   - type: Which entity to search for (release, artist, or release group).
    ///   - limit: Maximum results per page (MusicBrainz caps this at 100).
    ///   - offset: Zero-based offset for pagination.
    ///   - configuration: Request options (User-Agent).
    /// - Returns: A page of ``MBSearchResult`` plus the total match ``MBSearchResults/count``.
    public static func search(
        _ query: String,
        type: MusicBrainzSearchType,
        limit: Int = 25,
        offset: Int = 0,
        configuration: Configuration = .default
    ) async throws -> MBSearchResults {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw MusicBrainzMetadataError.invalidInput("the query is empty")
        }

        let items = [
            URLQueryItem(name: "query", value: trimmed),
            URLQueryItem(name: "limit", value: String(min(max(limit, 1), 100))),
            URLQueryItem(name: "offset", value: String(max(offset, 0)))
        ]
        let data = try await MusicBrainzClient.get(
            path: "/\(type.path)", queryItems: items, configuration: configuration
        )
        return MusicBrainzParser.searchResults(data, type: type)
    }

    // MARK: - Lookups

    /// Fetches a release by its MBID, including artist credits, labels, the
    /// tracklist (via recordings), and the Discogs URL relation.
    public static func release(
        _ mbid: String,
        configuration: Configuration = .default
    ) async throws -> MBRelease {
        let data = try await lookup(
            "release", mbid, inc: "artist-credits+labels+recordings+url-rels",
            configuration: configuration
        )
        return MusicBrainzParser.release(data)
    }

    /// Fetches an artist by its MBID, including aliases and the Discogs URL relation.
    public static func artist(
        _ mbid: String,
        configuration: Configuration = .default
    ) async throws -> MBArtist {
        let data = try await lookup(
            "artist", mbid, inc: "aliases+url-rels", configuration: configuration
        )
        return MusicBrainzParser.artist(data)
    }

    /// Fetches a release group by its MBID, including artist credits and the
    /// Discogs (master) URL relation.
    public static func releaseGroup(
        _ mbid: String,
        configuration: Configuration = .default
    ) async throws -> MBReleaseGroup {
        let data = try await lookup(
            "release-group", mbid, inc: "artist-credits+url-rels", configuration: configuration
        )
        return MusicBrainzParser.releaseGroup(data)
    }

    /// Fetches a recording by its MBID, including artist credits and URL relations.
    public static func recording(
        _ mbid: String,
        configuration: Configuration = .default
    ) async throws -> MBRecording {
        let data = try await lookup(
            "recording", mbid, inc: "artist-credits+url-rels", configuration: configuration
        )
        return MusicBrainzParser.recording(data)
    }

    /// Fetches a label by its MBID, including the Discogs URL relation.
    public static func label(
        _ mbid: String,
        configuration: Configuration = .default
    ) async throws -> MBLabel {
        let data = try await lookup(
            "label", mbid, inc: "url-rels", configuration: configuration
        )
        return MusicBrainzParser.label(data)
    }

    // MARK: - Helpers

    /// Performs a validated entity lookup with the given `inc` sub-queries.
    private static func lookup(
        _ entity: String,
        _ mbid: String,
        inc: String,
        configuration: Configuration
    ) async throws -> [String: Any] {
        let trimmed = mbid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard UUID(uuidString: trimmed) != nil else {
            throw MusicBrainzMetadataError.invalidInput(
                "\"\(mbid)\" is not an MBID — those are UUIDs, e.g. 5b11f4ce-a62d-471e-81fc-a69a8278c7da"
            )
        }
        let items = [URLQueryItem(name: "inc", value: inc)]
        return try await MusicBrainzClient.get(
            path: "/\(entity)/\(trimmed)", queryItems: items, configuration: configuration
        )
    }
}
