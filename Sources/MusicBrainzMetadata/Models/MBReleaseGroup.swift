//
//  MBReleaseGroup.swift
//  MusicBrainzMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A MusicBrainz release group — the canonical work (e.g. an album) that groups
/// together all its individual releases/editions.
///
/// Roughly the equivalent of a Discogs "master". Fetched with URL relations
/// included, exposing a cross-referenced ``discogsURL`` (a Discogs *master* link).
///
/// ```swift
/// let group = try await MusicBrainzMetadata.releaseGroup("1b022e01-4da6-387b-8658-8678046e4cef")
/// print("\(group.artistName) – \(group.title) [\(group.primaryType ?? "?")]")
/// print("first released \(group.firstReleaseDate ?? "?") · \(group.discogsURL ?? "—")")
/// ```
public struct MBReleaseGroup: Sendable, Identifiable {

    /// The release group MBID.
    public let id: String

    /// The title.
    public let title: String

    /// A short disambiguation comment, if any.
    public let disambiguation: String?

    /// The primary type (e.g. `"Album"`, `"Single"`, `"EP"`), if known.
    public let primaryType: String?

    /// Secondary types (e.g. `["Live"]`, `["Compilation"]`).
    public let secondaryTypes: [String]

    /// The earliest release date across the group, as text (e.g. `"1991-09-24"`).
    public let firstReleaseDate: String?

    /// The ordered artist credits.
    public let artistCredits: [MBArtistCredit]

    /// Every external URL MusicBrainz holds for this release group.
    ///
    /// Streaming, purchase, official and database links, classified but with
    /// ``MBExternalLink/relationType`` preserved verbatim. Use
    /// ``Swift/Collection/streaming`` for listen links, or
    /// ``Swift/Collection/url(for:)`` for one service.
    ///
    /// Populated at artist level in practice. Releases carry very few and
    /// recordings essentially none — see ``MBExternalLink`` for why.
    public let links: [MBExternalLink]

    /// The matching Discogs URL, when there is one.
    public var discogsURL: String? { links.url(for: .discogs) }

    /// The credited artists flattened for display.
    public var artistName: String { MBArtistCredit.combined(artistCredits) }

    public init(
        id: String, title: String, disambiguation: String?, primaryType: String?,
        secondaryTypes: [String], firstReleaseDate: String?,
        artistCredits: [MBArtistCredit], links: [MBExternalLink]
    ) {
        self.id = id
        self.title = title
        self.disambiguation = disambiguation
        self.primaryType = primaryType
        self.secondaryTypes = secondaryTypes
        self.firstReleaseDate = firstReleaseDate
        self.artistCredits = artistCredits
        self.links = links
    }
}
