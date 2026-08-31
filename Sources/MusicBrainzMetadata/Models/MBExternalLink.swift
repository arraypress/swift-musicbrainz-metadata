//
//  MBExternalLink.swift
//  MusicBrainzMetadata
//
//  Created by David Sherlock on 2026.
//
//  MusicBrainz's URL relations, kept rather than discarded.
//
//  Every lookup here already asks for `inc=url-rels`, and the response is rich:
//  Radiohead carries 57 relations, 16 of them streaming or purchase links —
//  Spotify, Apple Music, Tidal, Deezer, Amazon, Qobuz, YouTube Music,
//  SoundCloud, Bandcamp, Beatport. Only the Discogs one used to survive
//  parsing, so fifty-six links were fetched over the wire and thrown away.
//
//  One structural caveat worth knowing before building on this: these links
//  are maintained at **artist** level. A release carries almost none — OK
//  Computer has two relations, an Amazon ASIN and a Discogs link — and a
//  recording carries none at all. The community curates what is stable: one
//  artist maps to one Spotify page permanently, whereas an album has regional
//  variants, remasters and reissues. For album- and track-level links, an
//  aggregator such as Odesli is the right tool; this is not it.
//

import Foundation

// MARK: - Category

/// What an external link is for.
///
/// Derived from MusicBrainz's relation type, which is a free-form vocabulary
/// rather than an enum, so unrecognised types land in ``other`` rather than
/// being dropped.
public enum MBLinkCategory: String, Sendable, CaseIterable {

    /// Listen, whether by subscription or free.
    case streaming

    /// Buy, download, or order a physical copy.
    case purchase

    /// The artist's own site, blog, or fan pages.
    case official

    /// Profiles on social platforms.
    case social

    /// Other music databases and identifiers — Discogs, Wikidata, AllMusic.
    case database

    /// Lyrics, reviews, tour dates, and anything else.
    case other
}

// MARK: - Service

/// A recognised music service.
///
/// Matched on the URL's host rather than on the relation type: MusicBrainz
/// files Spotify under "free streaming" and Apple Music under both "streaming"
/// and "purchase for download", so the type says how you listen, not who you
/// listen with.
public enum MBService: String, Sendable, CaseIterable {
    case spotify
    case appleMusic
    case iTunes
    case tidal
    case deezer
    case amazonMusic
    case youtubeMusic
    case youtube
    case soundcloud
    case bandcamp
    case qobuz
    case beatport
    case audiomack
    case pandora
    case napster
    case anghami
    case boomplay
    case yandexMusic
    case sevenDigital
    case discogs
    case lastfm
    case allmusic
    case wikidata
    case genius
    case bleep

    /// Identifies a service from a URL's host.
    static func matching(host: String) -> MBService? {
        LinkClassification.service(forHost: host)
    }

    /// Whether this service is somewhere you can listen.
    public var isStreaming: Bool {
        switch self {
        case .spotify, .appleMusic, .tidal, .deezer, .amazonMusic, .youtubeMusic,
             .youtube, .soundcloud, .bandcamp, .qobuz, .audiomack, .pandora,
             .napster, .anghami, .boomplay, .yandexMusic:
            return true
        case .iTunes, .beatport, .sevenDigital, .discogs, .lastfm, .allmusic,
             .wikidata, .genius, .bleep:
            return false
        }
    }
}

// MARK: - Link

/// One external URL attached to a MusicBrainz entity.
public struct MBExternalLink: Sendable, Equatable, Identifiable, Hashable {

    public var id: String { url }

    /// The target URL.
    public let url: String

    /// MusicBrainz's own relation type, verbatim — `"free streaming"`,
    /// `"purchase for download"`, `"official homepage"`, and so on.
    ///
    /// Kept unmapped because the vocabulary grows, and a caller who knows
    /// MusicBrainz should not be limited to the subset modelled here.
    public let relationType: String

    /// The recognised service, when the host maps to one.
    public let service: MBService?

    /// What the link is for.
    public let category: MBLinkCategory

    public init(url: String, relationType: String, service: MBService?, category: MBLinkCategory) {
        self.url = url
        self.relationType = relationType
        self.service = service
        self.category = category
    }

    /// Classifies a relation type into a ``MBLinkCategory``.
    static func category(for relationType: String) -> MBLinkCategory {
        LinkClassification.category(forRelationType: relationType)
    }
}

// MARK: - Collection conveniences

public extension Collection where Element == MBExternalLink {

    /// Links in one category.
    func category(_ category: MBLinkCategory) -> [MBExternalLink] {
        filter { $0.category == category }
    }

    /// Everywhere you can listen, deduplicated by URL.
    ///
    /// Draws on the recognised service rather than the relation type alone,
    /// because MusicBrainz files Apple Music under both "streaming" and
    /// "purchase for download" and a listener wants it either way.
    var streaming: [MBExternalLink] {
        var seen = Set<String>()
        return filter { link in
            let listenable = link.category == .streaming || (link.service?.isStreaming ?? false)
            return listenable && seen.insert(link.url).inserted
        }
    }

    /// The first URL for a given service.
    func url(for service: MBService) -> String? {
        first { $0.service == service }?.url
    }

    var spotifyURL: String? { url(for: .spotify) }
    var appleMusicURL: String? { url(for: .appleMusic) }
    var tidalURL: String? { url(for: .tidal) }
    var deezerURL: String? { url(for: .deezer) }
    var bandcampURL: String? { url(for: .bandcamp) }
    var soundcloudURL: String? { url(for: .soundcloud) }
    var youtubeMusicURL: String? { url(for: .youtubeMusic) }
    var amazonMusicURL: String? { url(for: .amazonMusic) }
}
