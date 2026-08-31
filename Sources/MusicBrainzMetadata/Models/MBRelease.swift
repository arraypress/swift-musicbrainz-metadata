//
//  MBRelease.swift
//  MusicBrainzMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A single track on a ``MBMedium``.
public struct MBTrack: Sendable, Equatable, Identifiable {

    /// The track MBID.
    public let id: String

    /// The track title.
    public let title: String

    /// The printed track number (e.g. `"A1"`, `"3"`).
    public let number: String

    /// The 1-based position of the track on its medium.
    public let position: Int

    /// The track length in milliseconds, if known (falls back to the recording's length).
    public let length: Int?

    /// The MBID of the underlying recording, if present.
    public let recordingID: String?

    /// The track length formatted as `m:ss`, if known.
    public var lengthFormatted: String? {
        return length.map { Formatting.trackLength(ms: $0) }
    }

    public init(id: String, title: String, number: String, position: Int, length: Int?, recordingID: String?) {
        self.id = id
        self.title = title
        self.number = number
        self.position = position
        self.length = length
        self.recordingID = recordingID
    }
}

/// A physical or digital medium within a release (e.g. one disc of a set).
public struct MBMedium: Sendable, Equatable {

    /// The 1-based position of this medium within the release.
    public let position: Int

    /// The format (e.g. `"CD"`, `"12\" Vinyl"`), if known.
    public let format: String?

    /// The medium title, if it has one.
    public let title: String?

    /// The number of tracks on this medium.
    public let trackCount: Int

    /// The tracks on this medium (populated when `recordings` are requested).
    public let tracks: [MBTrack]

    public init(position: Int, format: String?, title: String?, trackCount: Int, tracks: [MBTrack]) {
        self.position = position
        self.format = format
        self.title = title
        self.trackCount = trackCount
        self.tracks = tracks
    }
}

/// A label credit on a release, pairing a label with its catalogue number.
public struct MBLabelInfo: Sendable, Equatable {

    /// The catalogue number (e.g. `"DGC-24425"`), if present.
    public let catalogNumber: String?

    /// The label's MBID, if present.
    public let labelID: String?

    /// The label's name, if present.
    public let labelName: String?

    public init(catalogNumber: String?, labelID: String?, labelName: String?) {
        self.catalogNumber = catalogNumber
        self.labelID = labelID
        self.labelName = labelName
    }
}

/// A MusicBrainz release — a specific edition/pressing of a record, CD, etc.
///
/// Fetched with recordings, labels and URL relations included, so the tracklist,
/// catalogue numbers, and a cross-referenced ``discogsURL`` are all available
/// from a single lookup.
///
/// ```swift
/// let release = try await MusicBrainzMetadata.release("b35c70b3-15f1-4792-a3d1-31645bde4db8")
/// print("\(release.artistName) – \(release.title) (\(release.date ?? "?"))")
/// print("\(release.trackCount) tracks · \(release.discogsURL ?? "no Discogs link")")
/// ```
public struct MBRelease: Sendable, Identifiable {

    /// The release MBID.
    public let id: String

    /// The release title.
    public let title: String

    /// A short disambiguation comment, if any.
    public let disambiguation: String?

    /// The ordered artist credits.
    public let artistCredits: [MBArtistCredit]

    /// The release date as text (e.g. `"1991-09-24"`), if known.
    public let date: String?

    /// The ISO country code of release (e.g. `"US"`), if known.
    public let country: String?

    /// The barcode, if present.
    public let barcode: String?

    /// The release status (e.g. `"Official"`, `"Promotion"`), if known.
    public let status: String?

    /// The packaging type (e.g. `"Jewel Case"`), if known.
    public let packaging: String?

    /// The label credits (label + catalogue number).
    public let labels: [MBLabelInfo]

    /// The media (discs) that make up the release, each with its tracklist.
    public let media: [MBMedium]

    /// Every external URL MusicBrainz holds for this release.
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

    /// The credited artists flattened for display (e.g. `"Queen & David Bowie"`).
    public var artistName: String { MBArtistCredit.combined(artistCredits) }

    /// Every track across all media, in order.
    public var tracks: [MBTrack] { media.flatMap { $0.tracks } }

    /// The total number of tracks across all media.
    public var trackCount: Int { media.reduce(0) { $0 + $1.trackCount } }

    public init(
        id: String, title: String, disambiguation: String?, artistCredits: [MBArtistCredit],
        date: String?, country: String?, barcode: String?, status: String?, packaging: String?,
        labels: [MBLabelInfo], media: [MBMedium], links: [MBExternalLink]
    ) {
        self.id = id
        self.title = title
        self.disambiguation = disambiguation
        self.artistCredits = artistCredits
        self.date = date
        self.country = country
        self.barcode = barcode
        self.status = status
        self.packaging = packaging
        self.labels = labels
        self.media = media
        self.links = links
    }
}
