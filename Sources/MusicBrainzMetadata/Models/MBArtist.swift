//
//  MBArtist.swift
//  MusicBrainzMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The active period of an artist or label.
public struct MBLifeSpan: Sendable, Equatable {

    /// The start date as text (e.g. `"1987"`), if known.
    public let begin: String?

    /// The end date as text (e.g. `"1994-04-05"`), if known.
    public let end: String?

    /// Whether the entity has ended (band split up, label closed, etc.).
    public let ended: Bool

    public init(begin: String?, end: String?, ended: Bool) {
        self.begin = begin
        self.end = end
        self.ended = ended
    }
}

/// An alternative name for an artist (localised name, abbreviation, etc.).
public struct MBAlias: Sendable, Equatable {

    /// The alias name.
    public let name: String

    /// The alias sort name, if provided.
    public let sortName: String?

    /// The BCP-47 locale of the alias (e.g. `"ja"`), if provided.
    public let locale: String?

    /// The alias type (e.g. `"Artist name"`, `"Search hint"`), if provided.
    public let type: String?

    /// Whether this is the primary alias for its locale.
    public let primary: Bool

    public init(name: String, sortName: String?, locale: String?, type: String?, primary: Bool) {
        self.name = name
        self.sortName = sortName
        self.locale = locale
        self.type = type
        self.primary = primary
    }
}

/// A MusicBrainz artist — a person or a group.
///
/// Fetched with aliases and URL relations included, exposing a cross-referenced
/// ``discogsURL`` alongside the artist's names and active period.
///
/// ```swift
/// let artist = try await MusicBrainzMetadata.artist("5b11f4ce-a62d-471e-81fc-a69a8278c7da")
/// print("\(artist.name) [\(artist.type ?? "?")] — \(artist.lifeSpan.begin ?? "?")")
/// print("Discogs: \(artist.discogsURL ?? "—")")
/// ```
public struct MBArtist: Sendable, Identifiable {

    /// The artist MBID.
    public let id: String

    /// The artist name.
    public let name: String

    /// The sort name (e.g. `"Beatles, The"`).
    public let sortName: String

    /// A short disambiguation comment, if any.
    public let disambiguation: String?

    /// The artist type (e.g. `"Person"`, `"Group"`), if known.
    public let type: String?

    /// The ISO country code associated with the artist, if known.
    public let country: String?

    /// The gender (for `Person` artists), if known.
    public let gender: String?

    /// The artist's active period.
    public let lifeSpan: MBLifeSpan

    /// Known aliases for the artist.
    public let aliases: [MBAlias]

    /// The matching Discogs artist URL, cross-referenced from URL relations.
    public let discogsURL: String?

    public init(
        id: String, name: String, sortName: String, disambiguation: String?,
        type: String?, country: String?, gender: String?, lifeSpan: MBLifeSpan,
        aliases: [MBAlias], discogsURL: String?
    ) {
        self.id = id
        self.name = name
        self.sortName = sortName
        self.disambiguation = disambiguation
        self.type = type
        self.country = country
        self.gender = gender
        self.lifeSpan = lifeSpan
        self.aliases = aliases
        self.discogsURL = discogsURL
    }
}
