//
//  MusicBrainzParser.swift
//  MusicBrainzMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Parses MusicBrainz web service response objects into typed models.
enum MusicBrainzParser {

    // MARK: - Release

    static func release(_ d: [String: Any]) -> MBRelease {
        MBRelease(
            id: d["id"] as? String ?? "",
            title: d["title"] as? String ?? "",
            disambiguation: nonEmpty(d["disambiguation"]),
            artistCredits: artistCredits(d["artist-credit"]),
            date: nonEmpty(d["date"]),
            country: nonEmpty(d["country"]),
            barcode: nonEmpty(d["barcode"]),
            status: nonEmpty(d["status"]),
            packaging: nonEmpty(d["packaging"]),
            labels: labelInfos(d["label-info"]),
            media: (d["media"] as? [[String: Any]] ?? []).map(medium),
            links: links(d["relations"])
        )
    }

    private static func medium(_ m: [String: Any]) -> MBMedium {
        MBMedium(
            position: intValue(m["position"]) ?? 0,
            format: nonEmpty(m["format"]),
            title: nonEmpty(m["title"]),
            trackCount: intValue(m["track-count"]) ?? 0,
            tracks: (m["tracks"] as? [[String: Any]] ?? []).map(track)
        )
    }

    private static func track(_ t: [String: Any]) -> MBTrack {
        let recording = t["recording"] as? [String: Any]
        return MBTrack(
            id: t["id"] as? String ?? "",
            title: t["title"] as? String ?? (recording?["title"] as? String ?? ""),
            number: t["number"] as? String ?? "",
            position: intValue(t["position"]) ?? 0,
            length: intValue(t["length"]) ?? intValue(recording?["length"]),
            recordingID: recording?["id"] as? String
        )
    }

    private static func labelInfos(_ value: Any?) -> [MBLabelInfo] {
        guard let array = value as? [[String: Any]] else { return [] }
        return array.map { info in
            let label = info["label"] as? [String: Any]
            return MBLabelInfo(
                catalogNumber: nonEmpty(info["catalog-number"]),
                labelID: label?["id"] as? String,
                labelName: label?["name"] as? String
            )
        }
    }

    // MARK: - Artist

    static func artist(_ d: [String: Any]) -> MBArtist {
        MBArtist(
            id: d["id"] as? String ?? "",
            name: d["name"] as? String ?? "",
            sortName: d["sort-name"] as? String ?? "",
            disambiguation: nonEmpty(d["disambiguation"]),
            type: nonEmpty(d["type"]),
            country: nonEmpty(d["country"]),
            gender: nonEmpty(d["gender"]),
            lifeSpan: lifeSpan(d["life-span"]),
            aliases: aliases(d["aliases"]),
            links: links(d["relations"])
        )
    }

    private static func aliases(_ value: Any?) -> [MBAlias] {
        guard let array = value as? [[String: Any]] else { return [] }
        return array.map {
            MBAlias(
                name: $0["name"] as? String ?? "",
                sortName: nonEmpty($0["sort-name"]),
                locale: nonEmpty($0["locale"]),
                type: nonEmpty($0["type"]),
                primary: $0["primary"] as? Bool ?? false
            )
        }
    }

    // MARK: - Release group

    static func releaseGroup(_ d: [String: Any]) -> MBReleaseGroup {
        MBReleaseGroup(
            id: d["id"] as? String ?? "",
            title: d["title"] as? String ?? "",
            disambiguation: nonEmpty(d["disambiguation"]),
            primaryType: nonEmpty(d["primary-type"]),
            secondaryTypes: stringArray(d["secondary-types"]),
            firstReleaseDate: nonEmpty(d["first-release-date"]),
            artistCredits: artistCredits(d["artist-credit"]),
            links: links(d["relations"])
        )
    }

    // MARK: - Recording

    static func recording(_ d: [String: Any]) -> MBRecording {
        MBRecording(
            id: d["id"] as? String ?? "",
            title: d["title"] as? String ?? "",
            disambiguation: nonEmpty(d["disambiguation"]),
            length: intValue(d["length"]),
            firstReleaseDate: nonEmpty(d["first-release-date"]),
            video: d["video"] as? Bool ?? false,
            artistCredits: artistCredits(d["artist-credit"]),
            links: links(d["relations"])
        )
    }

    // MARK: - Label

    static func label(_ d: [String: Any]) -> MBLabel {
        MBLabel(
            id: d["id"] as? String ?? "",
            name: d["name"] as? String ?? "",
            sortName: nonEmpty(d["sort-name"]),
            disambiguation: nonEmpty(d["disambiguation"]),
            type: nonEmpty(d["type"]),
            country: nonEmpty(d["country"]),
            labelCode: intValue(d["label-code"]),
            area: (d["area"] as? [String: Any])?["name"] as? String,
            lifeSpan: lifeSpan(d["life-span"]),
            links: links(d["relations"])
        )
    }

    // MARK: - Search

    static func searchResults(_ d: [String: Any], type: MusicBrainzSearchType) -> MBSearchResults {
        let items = (d[type.resultsKey] as? [[String: Any]] ?? []).map { searchResult($0, type: type) }
        return MBSearchResults(
            results: items,
            count: intValue(d["count"]) ?? items.count,
            offset: intValue(d["offset"]) ?? 0
        )
    }

    private static func searchResult(_ d: [String: Any], type: MusicBrainzSearchType) -> MBSearchResult {
        let credits = artistCredits(d["artist-credit"])
        return MBSearchResult(
            id: d["id"] as? String ?? "",
            type: type.entityName,
            score: intValue(d["score"]) ?? 0,
            title: d["title"] as? String ?? (d["name"] as? String ?? ""),
            disambiguation: nonEmpty(d["disambiguation"]),
            artistName: credits.isEmpty ? nil : MBArtistCredit.combined(credits),
            sortName: nonEmpty(d["sort-name"]),
            date: nonEmpty(d["date"]) ?? nonEmpty(d["first-release-date"]),
            country: nonEmpty(d["country"]),
            primaryType: nonEmpty(d["primary-type"])
        )
    }

    // MARK: - Shared

    /// Parses an ordered `artist-credit` array.
    private static func artistCredits(_ value: Any?) -> [MBArtistCredit] {
        guard let credits = value as? [[String: Any]] else { return [] }
        return credits.map { credit in
            let artist = credit["artist"] as? [String: Any]
            return MBArtistCredit(
                name: credit["name"] as? String ?? (artist?["name"] as? String ?? ""),
                joinPhrase: nonEmpty(credit["joinphrase"]),
                artistID: artist?["id"] as? String,
                artistName: artist?["name"] as? String,
                sortName: artist?["sort-name"] as? String,
                disambiguation: nonEmpty(artist?["disambiguation"])
            )
        }
    }

    /// Parses a `life-span` object.
    private static func lifeSpan(_ value: Any?) -> MBLifeSpan {
        let d = value as? [String: Any]
        return MBLifeSpan(
            begin: nonEmpty(d?["begin"]),
            end: nonEmpty(d?["end"]),
            ended: d?["ended"] as? Bool ?? false
        )
    }

    /// Parses a `relations` array into typed external links.
    ///
    /// Every relation is kept, not just Discogs. The response already carries
    /// them — Radiohead's artist record has 57 — and discarding the other 56
    /// was throwing away the Spotify, Apple Music and Tidal links the caller
    /// paid for over the wire.
    ///
    /// Relations without a URL target (artist-to-artist credits, for instance)
    /// are skipped rather than emitted with an empty string.
    private static func links(_ value: Any?) -> [MBExternalLink] {
        guard let relations = value as? [[String: Any]] else { return [] }

        var seen = Set<String>()
        return relations.compactMap { relation in
            guard let target = relation["url"] as? [String: Any],
                  let resource = target["resource"] as? String,
                  !resource.isEmpty,
                  seen.insert(resource).inserted
            else { return nil }

            let type = relation["type"] as? String ?? ""
            return MBExternalLink(
                url: resource,
                relationType: type,
                service: host(of: resource).flatMap(MBService.matching(host:)),
                category: MBExternalLink.category(for: type)
            )
        }
    }

    /// The host of a URL, tolerating the malformed entries MusicBrainz holds.
    private static func host(of urlString: String) -> String? {
        URLComponents(string: urlString)?.host
    }

    // MARK: - Helpers

    /// Returns the string if non-empty, else `nil`. Accepts non-string values as `nil`.
    private static func nonEmpty(_ value: Any?) -> String? {
        guard let s = value as? String, !s.isEmpty else { return nil }
        return s
    }

    private static func stringArray(_ value: Any?) -> [String] {
        value as? [String] ?? []
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let i = value as? Int { return i }
        if let s = value as? String { return Int(s) }
        if let d = value as? Double { return Int(d) }
        return nil
    }
}
