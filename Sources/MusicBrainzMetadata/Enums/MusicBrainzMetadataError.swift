//
//  MusicBrainzMetadataError.swift
//  MusicBrainzMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Errors that can occur when calling the MusicBrainz web service.
public enum MusicBrainzMetadataError: Error, LocalizedError, Equatable, Sendable {

    /// The input could not be parsed into a valid MBID (UUID) or query, or
    /// MusicBrainz rejected the request as malformed (`400`).
    ///
    /// Distinct from ``notFound``: the request never got as far as looking for
    /// anything, so the record it named is not the problem.
    case invalidInput(String)

    /// The requested resource does not exist (`404`).
    case notFound

    /// MusicBrainz declined to serve the request right now (`503`), with the
    /// `Retry-After` it sent if it sent one.
    ///
    /// The service meters against a bucket shared by everyone rather than one
    /// per client, so this arrives even when a single caller is well behaved.
    /// A missing or generic `User-Agent` also earns a `503`, and that one does
    /// not clear by waiting.
    case rateLimited(Double?)

    /// MusicBrainz returned an error payload.
    case apiError(String)

    /// A network request failed.
    case networkError(String)

    /// Failed to parse the response.
    case parsingError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "MusicBrainz could not parse the request: \(message)"
        case .notFound:
            return "The requested MusicBrainz resource was not found."
        case .rateLimited(let retryAfter):
            let wait = retryAfter.map { " Retry after \(Int($0))s." } ?? ""
            return "MusicBrainz is declining requests right now.\(wait) Its rate limit is shared between all callers, so this can happen even when you are pacing correctly. A generic User-Agent also causes it, and that does not clear by waiting."
        case .apiError(let message):
            return "MusicBrainz API error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        }
    }
}
