//
//  MusicBrainzSearchType.swift
//  MusicBrainzMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The type of MusicBrainz entity to search for.
public enum MusicBrainzSearchType: Sendable {
    /// A specific release (a particular edition/pressing).
    case release
    /// An artist (a person or group).
    case artist
    /// A release group (the canonical work grouping its releases).
    case releaseGroup

    /// The path segment used by the MusicBrainz search endpoint
    /// (e.g. `"release-group"`).
    var path: String {
        switch self {
        case .release: return "release"
        case .artist: return "artist"
        case .releaseGroup: return "release-group"
        }
    }

    /// The JSON key the results are nested under in the response
    /// (e.g. `"release-groups"`).
    var resultsKey: String {
        switch self {
        case .release: return "releases"
        case .artist: return "artists"
        case .releaseGroup: return "release-groups"
        }
    }

    /// The canonical entity name reported on each ``MBSearchResult``.
    var entityName: String { path }
}
