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

    /// The matching Discogs master URL, cross-referenced from URL relations.
    public let discogsURL: String?

    /// The credited artists flattened for display.
    public var artistName: String { MBArtistCredit.combined(artistCredits) }

    public init(
        id: String, title: String, disambiguation: String?, primaryType: String?,
        secondaryTypes: [String], firstReleaseDate: String?,
        artistCredits: [MBArtistCredit], discogsURL: String?
    ) {
        self.id = id
        self.title = title
        self.disambiguation = disambiguation
        self.primaryType = primaryType
        self.secondaryTypes = secondaryTypes
        self.firstReleaseDate = firstReleaseDate
        self.artistCredits = artistCredits
        self.discogsURL = discogsURL
    }
}
