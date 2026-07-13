//
//  MBArtistCredit.swift
//  MusicBrainzMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A single artist credit as it appears on a release, release group, or recording.
///
/// MusicBrainz represents "credited to" strings as an ordered list of credits,
/// each with an optional `joinPhrase` (e.g. `" feat. "`) so that collaborations
/// render exactly as printed. Use ``MBArtistCredit/combined(_:)`` to flatten a
/// list back into a display string.
public struct MBArtistCredit: Sendable, Equatable {

    /// The credited name (may differ from the artist's canonical name).
    public let name: String

    /// The phrase that joins this credit to the next (e.g. `" feat. "`, `" & "`).
    public let joinPhrase: String?

    /// The MusicBrainz MBID of the credited artist, if present.
    public let artistID: String?

    /// The artist's canonical name.
    public let artistName: String?

    /// The artist's sort name (e.g. `"Beatles, The"`).
    public let sortName: String?

    /// A short disambiguation comment (e.g. `"1980s–1990s US grunge band"`).
    public let disambiguation: String?

    public init(
        name: String, joinPhrase: String?, artistID: String?,
        artistName: String?, sortName: String?, disambiguation: String?
    ) {
        self.name = name
        self.joinPhrase = joinPhrase
        self.artistID = artistID
        self.artistName = artistName
        self.sortName = sortName
        self.disambiguation = disambiguation
    }

    /// Flattens a list of credits into a single display string, honouring each
    /// credit's join phrase (e.g. `"Queen & David Bowie"`).
    public static func combined(_ credits: [MBArtistCredit]) -> String {
        credits
            .map { $0.name + ($0.joinPhrase ?? "") }
            .joined()
            .trimmingCharacters(in: .whitespaces)
    }
}
