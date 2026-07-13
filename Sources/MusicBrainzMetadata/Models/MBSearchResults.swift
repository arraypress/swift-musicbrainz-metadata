//
//  MBSearchResults.swift
//  MusicBrainzMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A single MusicBrainz search hit.
///
/// A lightweight, entity-agnostic summary covering the fields common to release,
/// artist, and release-group searches. Follow up with a typed lookup
/// (e.g. ``MusicBrainzMetadata/release(_:configuration:)``) using ``id`` for full detail.
public struct MBSearchResult: Sendable, Identifiable {

    /// The entity MBID.
    public let id: String

    /// The entity type (`"release"`, `"artist"`, or `"release-group"`).
    public let type: String

    /// The relevance score (0–100) MusicBrainz assigned to this hit.
    public let score: Int

    /// The primary display text — a title for releases/groups, or a name for artists.
    public let title: String

    /// A short disambiguation comment, if any.
    public let disambiguation: String?

    /// The credited artists flattened for display, for release/release-group hits.
    public let artistName: String?

    /// The sort name, for artist hits.
    public let sortName: String?

    /// The date (releases) or first-release-date (release groups) as text, if known.
    public let date: String?

    /// The ISO country code, if known.
    public let country: String?

    /// The primary type (e.g. `"Album"`), for release-group hits.
    public let primaryType: String?

    public init(
        id: String, type: String, score: Int, title: String, disambiguation: String?,
        artistName: String?, sortName: String?, date: String?, country: String?,
        primaryType: String?
    ) {
        self.id = id
        self.type = type
        self.score = score
        self.title = title
        self.disambiguation = disambiguation
        self.artistName = artistName
        self.sortName = sortName
        self.date = date
        self.country = country
        self.primaryType = primaryType
    }
}

/// A page of MusicBrainz search results with the total match ``count``.
///
/// MusicBrainz paginates by ``offset``/limit; ``count`` is the total number of
/// matches across all pages, so ``hasMore`` reports whether more remain.
public struct MBSearchResults: Sendable {

    /// The results on this page.
    public let results: [MBSearchResult]

    /// The total number of matching entities across all pages.
    public let count: Int

    /// The zero-based offset of the first result on this page.
    public let offset: Int

    /// Whether more results exist beyond this page.
    public var hasMore: Bool { offset + results.count < count }

    public init(results: [MBSearchResult], count: Int, offset: Int) {
        self.results = results
        self.count = count
        self.offset = offset
    }
}
