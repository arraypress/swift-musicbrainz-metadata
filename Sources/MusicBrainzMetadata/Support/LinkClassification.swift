//
//  LinkClassification.swift
//  MusicBrainzMetadata
//
//  Created by David Sherlock on 2026.
//
//  The two tables that turn MusicBrainz's free-form URL relations into
//  typed links: host → service, relation type → category. Pure
//  functions, pinned directly — the models delegate.
//

import Foundation

/// Classifying external links by host and by relation type.
enum LinkClassification {

    /// Identifies a service from a URL's host.
    static func service(forHost host: String) -> MBService? {
        let bare = host.lowercased().hasPrefix("www.")
            ? String(host.lowercased().dropFirst(4))
            : host.lowercased()

        // Ordered longest-first where hosts nest: music.youtube.com must be
        // tested before youtube.com, and music.apple.com before apple.com.
        let table: [(String, MBService)] = [
            ("open.spotify.com", .spotify),
            ("play.spotify.com", .spotify),
            ("music.apple.com", .appleMusic),
            ("itunes.apple.com", .iTunes),
            ("music.youtube.com", .youtubeMusic),
            ("music.amazon.", .amazonMusic),
            ("music.yandex.", .yandexMusic),
            ("tidal.com", .tidal),
            ("deezer.com", .deezer),
            ("napster.com", .napster),
            ("youtube.com", .youtube),
            ("youtu.be", .youtube),
            ("soundcloud.com", .soundcloud),
            ("bandcamp.com", .bandcamp),
            ("qobuz.com", .qobuz),
            ("beatport.com", .beatport),
            ("audiomack.com", .audiomack),
            ("pandora.com", .pandora),
            ("anghami.com", .anghami),
            ("boomplay.com", .boomplay),
            ("7digital.com", .sevenDigital),
            ("discogs.com", .discogs),
            ("last.fm", .lastfm),
            ("allmusic.com", .allmusic),
            ("wikidata.org", .wikidata),
            ("genius.com", .genius),
            ("bleep.com", .bleep),
        ]

        for (needle, service) in table {
            // A needle ending in "." is a prefix pattern, covering the
            // per-region hosts Apple and Amazon use — music.amazon.co.uk,
            // music.amazon.de and so on.
            let matched = needle.hasSuffix(".")
                ? bare.hasPrefix(needle)
                : (bare == needle || bare.hasSuffix("." + needle))
            if matched { return service }
        }
        return nil
    }

    /// Classifies a relation type into a ``MBLinkCategory``.
    static func category(forRelationType relationType: String) -> MBLinkCategory {
        switch relationType.lowercased() {
        case "free streaming", "streaming", "download for free",
             "youtube music", "soundcloud", "bandcamp", "youtube", "video channel":
            return .streaming
        case "purchase for download", "purchase for mail-order", "get the music":
            return .purchase
        case "official homepage", "blog", "fanpage", "discography page", "myspace":
            return .official
        case "social network":
            return .social
        case "discogs", "wikidata", "allmusic", "vgmdb", "secondhandsongs",
             "other databases", "viaf", "imdb", "bbc music page", "last.fm":
            return .database
        default:
            return .other
        }
    }
}
