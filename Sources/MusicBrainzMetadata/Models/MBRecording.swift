//
//  MBRecording.swift
//  MusicBrainzMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A MusicBrainz recording — a unique audio recording that can appear as a track
/// on many releases.
///
/// ```swift
/// let recording = try await MusicBrainzMetadata.recording("5fb524f1-8cc8-4c04-a921-e34c0a911ea7")
/// print("\(recording.artistName) – \(recording.title) (\(recording.lengthFormatted ?? "?"))")
/// ```
public struct MBRecording: Sendable, Identifiable {

    /// The recording MBID.
    public let id: String

    /// The recording title.
    public let title: String

    /// A short disambiguation comment, if any.
    public let disambiguation: String?

    /// The recording length in milliseconds, if known.
    public let length: Int?

    /// The earliest release date for this recording, as text, if known.
    public let firstReleaseDate: String?

    /// Whether the recording is a video.
    public let video: Bool

    /// The ordered artist credits.
    public let artistCredits: [MBArtistCredit]

    /// The matching Discogs URL, cross-referenced from URL relations, if any.
    public let discogsURL: String?

    /// The credited artists flattened for display.
    public var artistName: String { MBArtistCredit.combined(artistCredits) }

    /// The recording length formatted as `m:ss`, if known.
    public var lengthFormatted: String? {
        guard let length else { return nil }
        let totalSeconds = length / 1000
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    public init(
        id: String, title: String, disambiguation: String?, length: Int?,
        firstReleaseDate: String?, video: Bool, artistCredits: [MBArtistCredit],
        discogsURL: String?
    ) {
        self.id = id
        self.title = title
        self.disambiguation = disambiguation
        self.length = length
        self.firstReleaseDate = firstReleaseDate
        self.video = video
        self.artistCredits = artistCredits
        self.discogsURL = discogsURL
    }
}
