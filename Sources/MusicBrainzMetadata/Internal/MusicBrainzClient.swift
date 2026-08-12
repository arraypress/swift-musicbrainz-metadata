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
/// with a generic one) are rejected with `503`.
///
/// It also meters requests, and the bucket is shared rather than per-client —
/// `x-ratelimit-remaining` moves with everyone's traffic. A well-paced client
/// still meets a 503 now and then, so one is retried rather than reported. See
/// ``get(path:queryItems:configuration:)``.
enum MusicBrainzClient {

    // MARK: - Configuration

    /// The MusicBrainz web service base URL.
    static let host = "https://musicbrainz.org/ws/2"

    // MARK: - Requests

    /// Issues a `GET` against `path`, always requesting JSON, and returns the
    /// decoded top-level object.
    /// Issues the request, retrying a 503 up to
    /// ``MusicBrainzMetadata/Configuration/retryLimit`` times.
    ///
    /// `Retry-After` is honoured when sent and a second is waited otherwise,
    /// which is the documented floor for this service. Nothing else is
    /// retried: a 404 will still be a 404 next time, and repeating a request
    /// that was refused on its merits is how a client earns a longer ban.
    static func get(
        path: String,
        queryItems: [URLQueryItem] = [],
        configuration: MusicBrainzMetadata.Configuration
    ) async throws -> [String: Any] {
        var attempt = 0
        while true {
            do {
                return try await attemptGet(
                    path: path, queryItems: queryItems, configuration: configuration
                )
            } catch let error as MusicBrainzMetadataError {
                guard case .rateLimited(let retryAfter) = error, attempt < configuration.retryLimit else {
                    throw error
                }
                attempt += 1
                let seconds = retryAfter ?? Double(attempt)
                try? await Task.sleep(for: .milliseconds(Int(seconds * 1000)))
            }
        }
    }

    private static func attemptGet(
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
            // 400 is a request MusicBrainz could not parse — a malformed MBID,
            // or Lucene syntax it rejected. Reporting that as "not found"
            // sends somebody looking for a record that was never the problem.
            case 400: throw MusicBrainzMetadataError.invalidInput(message ?? "MusicBrainz rejected the request")
            case 404: throw MusicBrainzMetadataError.notFound
            case 503:
                let header = http.value(forHTTPHeaderField: "Retry-After")
                throw MusicBrainzMetadataError.rateLimited(header.flatMap(Double.init))
            default: throw MusicBrainzMetadataError.apiError(message ?? "HTTP \(http.statusCode)")
            }
        }

        guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw MusicBrainzMetadataError.parsingError("Invalid JSON response")
        }
        return json
    }
}
