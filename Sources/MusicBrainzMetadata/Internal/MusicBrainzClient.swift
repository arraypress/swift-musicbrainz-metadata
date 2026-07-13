//
//  MusicBrainzClient.swift
//  MusicBrainzMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Performs GET requests against the MusicBrainz web service.
///
/// MusicBrainz **requires** a descriptive `User-Agent`; requests without one (or
/// with a generic one) are rejected with `503`. It also rate-limits to roughly
/// one request per second — callers should pace their requests accordingly.
enum MusicBrainzClient {

    // MARK: - Configuration

    /// The MusicBrainz web service base URL.
    static let host = "https://musicbrainz.org/ws/2"

    // MARK: - Requests

    /// Issues a `GET` against `path`, always requesting JSON, and returns the
    /// decoded top-level object.
    static func get(
        path: String,
        queryItems: [URLQueryItem] = [],
        configuration: MusicBrainzMetadata.Configuration
    ) async throws -> [String: Any] {
        guard var components = URLComponents(string: host + path) else {
            throw MusicBrainzMetadataError.networkError("Invalid request URL")
        }
        var items = queryItems
        items.append(URLQueryItem(name: "fmt", value: "json"))
        components.queryItems = items
        guard let url = components.url else {
            throw MusicBrainzMetadataError.networkError("Invalid request URL")
        }

        var request = URLRequest(url: url)
        request.setValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw MusicBrainzMetadataError.networkError(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let message = ((try? JSONSerialization.jsonObject(with: data)) as? [String: Any])?["error"] as? String
            switch http.statusCode {
            case 400, 404: throw MusicBrainzMetadataError.notFound
            case 503: throw MusicBrainzMetadataError.rateLimited
            default: throw MusicBrainzMetadataError.apiError(message ?? "HTTP \(http.statusCode)")
            }
        }

        guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw MusicBrainzMetadataError.parsingError("Invalid JSON response")
        }
        return json
    }
}
