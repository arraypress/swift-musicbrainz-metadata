//
//  MusicBrainzMetadataError.swift
//  MusicBrainzMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Errors that can occur when calling the MusicBrainz web service.
public enum MusicBrainzMetadataError: Error, LocalizedError, Equatable, Sendable {

    /// The provided input could not be parsed into a valid MBID (UUID) or query.
    case invalidInput

    /// The requested resource was not found (`404`), or the MBID was rejected (`400`).
    case notFound

    /// MusicBrainz is rate-limiting requests (`503`). The service allows roughly
    /// one request per second; a missing or generic `User-Agent` also triggers `503`.
    case rateLimited

    /// MusicBrainz returned an error payload.
    case apiError(String)

    /// A network request failed.
    case networkError(String)

    /// Failed to parse the response.
    case parsingError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Could not parse a valid MusicBrainz MBID (UUID) or query from the input."
        case .notFound:
            return "The requested MusicBrainz resource was not found."
        case .rateLimited:
            return "MusicBrainz is rate-limiting requests (max ~1/sec). Ensure a descriptive User-Agent is set and slow down."
        case .apiError(let message):
            return "MusicBrainz API error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        }
    }
}
