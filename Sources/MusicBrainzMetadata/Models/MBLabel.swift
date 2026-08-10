//
//  MBLabel.swift
//  MusicBrainzMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A MusicBrainz label — a record label or imprint.
///
/// Fetched with URL relations included, exposing a cross-referenced ``discogsURL``.
///
/// ```swift
/// let label = try await MusicBrainzMetadata.label("68803e28-86fe-4a95-985f-8e493795ab31")
/// print("\(label.name) [\(label.type ?? "?")] — \(label.area ?? "?")")
/// ```
public struct MBLabel: Sendable, Identifiable {

    /// The label MBID.
    public let id: String

    /// The label name.
    public let name: String

    /// The sort name, if provided.
    public let sortName: String?

    /// A short disambiguation comment, if any.
    public let disambiguation: String?

    /// The label type (e.g. `"Original Production"`, `"Imprint"`), if known.
    public let type: String?

    /// The ISO country code associated with the label, if known.
    public let country: String?

    /// The numeric label code (LC), if assigned.
    public let labelCode: Int?

    /// The name of the label's associated area (e.g. `"United States"`), if known.
    public let area: String?

    /// The label's active period.
    public let lifeSpan: MBLifeSpan

    /// Every external URL MusicBrainz holds for this label.
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

    public init(
        id: String, name: String, sortName: String?, disambiguation: String?,
        type: String?, country: String?, labelCode: Int?, area: String?,
        lifeSpan: MBLifeSpan, links: [MBExternalLink]
    ) {
        self.id = id
        self.name = name
        self.sortName = sortName
        self.disambiguation = disambiguation
        self.type = type
        self.country = country
        self.labelCode = labelCode
        self.area = area
        self.lifeSpan = lifeSpan
        self.links = links
    }
}
