//
//  MusicBrainzMetadataTests.swift
//  MusicBrainzMetadata
//
//  Created by David Sherlock on 2026.
//

import XCTest
@testable import MusicBrainzMetadata

final class MusicBrainzMetadataTests: XCTestCase {

    // MARK: - Release parsing

    func testParseRelease() throws {
        let release = MusicBrainzParser.release(try json(Fixture.release))
        XCTAssertEqual(release.id, "b35c70b3-15f1-4792-a3d1-31645bde4db8")
        XCTAssertEqual(release.title, "Nevermind")
        XCTAssertEqual(release.artistName, "Nirvana")
        XCTAssertEqual(release.artistCredits.first?.artistID, "5b11f4ce-a62d-471e-81fc-a69a8278c7da")
        XCTAssertEqual(release.date, "2011-10-04")
        XCTAssertEqual(release.country, "US")
        XCTAssertEqual(release.barcode, "602527779041")
        XCTAssertEqual(release.status, "Official")

        // Labels
        XCTAssertEqual(release.labels.count, 1)
        XCTAssertEqual(release.labels.first?.labelName, "DGC Records")
        XCTAssertEqual(release.labels.first?.catalogNumber, "B0015884-01")

        // Media + tracks
        XCTAssertEqual(release.media.count, 1)
        XCTAssertEqual(release.media.first?.format, "12\" Vinyl")
        XCTAssertEqual(release.trackCount, 2)
        XCTAssertEqual(release.tracks.count, 2)
        let track = try XCTUnwrap(release.tracks.first)
        XCTAssertEqual(track.title, "Smells Like Teen Spirit")
        XCTAssertEqual(track.number, "A1")
        XCTAssertEqual(track.position, 1)
        // Track length falls back to the recording's length.
        XCTAssertEqual(track.length, 301133)
        XCTAssertEqual(track.lengthFormatted, "5:01")

        // Discogs cross-reference
        XCTAssertEqual(release.discogsURL, "https://www.discogs.com/release/3183667")
    }

    // MARK: - Artist parsing

    func testParseArtist() throws {
        let artist = MusicBrainzParser.artist(try json(Fixture.artist))
        XCTAssertEqual(artist.id, "5b11f4ce-a62d-471e-81fc-a69a8278c7da")
        XCTAssertEqual(artist.name, "Nirvana")
        XCTAssertEqual(artist.sortName, "Nirvana")
        XCTAssertEqual(artist.type, "Group")
        XCTAssertEqual(artist.country, "US")
        XCTAssertEqual(artist.disambiguation, "1980s–1990s US grunge band")
        XCTAssertEqual(artist.lifeSpan.begin, "1987")
        XCTAssertEqual(artist.lifeSpan.end, "1994-04-05")
        XCTAssertTrue(artist.lifeSpan.ended)
        XCTAssertEqual(artist.aliases.count, 2)
        XCTAssertEqual(artist.aliases.first?.name, "Nirvana")
        XCTAssertEqual(artist.aliases.first?.locale, "en")
        XCTAssertTrue(artist.aliases.first?.primary ?? false)
        XCTAssertEqual(artist.discogsURL, "https://www.discogs.com/artist/125246")
    }

    // MARK: - External links

    func testAllRelationsSurviveNotJustDiscogs() throws {
        // The defect this replaced: `inc=url-rels` was requested, the response
        // carried every link, and only Discogs was parsed out.
        let artist = MusicBrainzParser.artist(try json(Fixture.artist))
        XCTAssertEqual(artist.links.count, 11, "one relation has no URL target and is skipped")
        XCTAssertEqual(artist.discogsURL, "https://www.discogs.com/artist/125246")
    }

    func testStreamingServicesAreRecognisedByHost() throws {
        let links = MusicBrainzParser.artist(try json(Fixture.artist)).links
        XCTAssertEqual(links.spotifyURL, "https://open.spotify.com/artist/6olE6TJLqED3rqDCT0FyPh")
        XCTAssertEqual(links.appleMusicURL, "https://music.apple.com/gb/artist/112018")
        XCTAssertEqual(links.tidalURL, "https://tidal.com/artist/16928")
        XCTAssertEqual(links.deezerURL, "https://www.deezer.com/artist/604")
        XCTAssertEqual(links.youtubeMusicURL, "https://music.youtube.com/channel/UCJ6QMrpAHNfMGjnCbnzWvEA")
    }

    func testAppleMusicIsFoundUnderEitherRelationType() throws {
        // MusicBrainz files it as both "streaming" and "purchase for download".
        // Matching on host rather than relation type is what makes it findable.
        let links = MusicBrainzParser.artist(try json(Fixture.artist)).links
        let apple = links.filter { $0.service == .appleMusic }
        XCTAssertEqual(apple.count, 1, "the duplicate URL is collapsed")
        XCTAssertEqual(apple.first?.relationType, "streaming")
    }

    func testStreamingCollectionExcludesPurchaseOnlyServices() throws {
        let links = MusicBrainzParser.artist(try json(Fixture.artist)).links
        let hosts = Set(links.streaming.compactMap { $0.service })
        XCTAssertTrue(hosts.contains(.spotify))
        XCTAssertTrue(hosts.contains(.appleMusic))
        XCTAssertFalse(hosts.contains(.beatport), "Beatport is a shop, not a streaming service")
        XCTAssertFalse(hosts.contains(.discogs))
    }

    func testCategoriesSortRelationTypes() throws {
        let links = MusicBrainzParser.artist(try json(Fixture.artist)).links
        XCTAssertEqual(links.category(.social).first?.url, "https://twitter.com/nirvana")
        XCTAssertEqual(links.category(.official).first?.url, "https://www.nirvana.com/")
        XCTAssertTrue(links.category(.database).contains { $0.service == .wikidata })
        XCTAssertTrue(links.category(.purchase).contains { $0.service == .beatport })
    }

    func testRelationTypeIsPreservedVerbatim() throws {
        // The vocabulary grows; a caller who knows MusicBrainz should not be
        // limited to the categories modelled here.
        let links = MusicBrainzParser.artist(try json(Fixture.artist)).links
        XCTAssertTrue(links.contains { $0.relationType == "free streaming" })
        XCTAssertTrue(links.contains { $0.relationType == "purchase for download" })
    }

    func testRelationsWithoutAURLAreSkipped() throws {
        // Artist-to-artist relations have no `url` object at all.
        let links = MusicBrainzParser.artist(try json(Fixture.artist)).links
        XCTAssertFalse(links.contains { $0.url.isEmpty })
    }

    func testUnknownHostsStillProduceALink() {
        let link = MBExternalLink(
            url: "https://obscure.example.com/x",
            relationType: "free streaming",
            service: MBService.matching(host: "obscure.example.com"),
            category: MBExternalLink.category(for: "free streaming")
        )
        XCTAssertNil(link.service)
        XCTAssertEqual(link.category, .streaming, "an unrecognised host is still a streaming link")
    }

    func testRegionalHostsResolve() {
        // Found live: us.napster.com was missed by a table holding only
        // play.napster.com, and Apple/Amazon vary the host per country.
        XCTAssertEqual(MBService.matching(host: "us.napster.com"), .napster)
        XCTAssertEqual(MBService.matching(host: "play.napster.com"), .napster)
        XCTAssertEqual(MBService.matching(host: "music.amazon.co.uk"), .amazonMusic)
        XCTAssertEqual(MBService.matching(host: "music.amazon.de"), .amazonMusic)
        XCTAssertEqual(MBService.matching(host: "listen.tidal.com"), .tidal)
        XCTAssertEqual(MBService.matching(host: "music.yandex.ru"), .yandexMusic)
    }

    func testHostMatchingIsNotSubstringLoose() {
        // A `contains` check would have matched these; suffix matching does not.
        XCTAssertNil(MBService.matching(host: "nottidal.com.example.org"))
        XCTAssertNil(MBService.matching(host: "spotify.com.phishing.example"))
    }

    func testNestedHostsResolveToTheMoreSpecificService() {
        XCTAssertEqual(MBService.matching(host: "music.youtube.com"), .youtubeMusic)
        XCTAssertEqual(MBService.matching(host: "www.youtube.com"), .youtube)
        XCTAssertEqual(MBService.matching(host: "music.apple.com"), .appleMusic)
        XCTAssertEqual(MBService.matching(host: "itunes.apple.com"), .iTunes)
        XCTAssertEqual(MBService.matching(host: "radiohead.bandcamp.com"), .bandcamp)
    }

    // MARK: - Release group parsing

    func testParseReleaseGroup() throws {
        let group = MusicBrainzParser.releaseGroup(try json(Fixture.releaseGroup))
        XCTAssertEqual(group.id, "1b022e01-4da6-387b-8658-8678046e4cef")
        XCTAssertEqual(group.title, "Nevermind")
        XCTAssertEqual(group.primaryType, "Album")
        XCTAssertEqual(group.firstReleaseDate, "1991-09-24")
        XCTAssertEqual(group.artistName, "Nirvana")
        XCTAssertEqual(group.discogsURL, "https://www.discogs.com/master/13814")
    }

    // MARK: - Recording parsing

    func testParseRecording() throws {
        let recording = MusicBrainzParser.recording(try json(Fixture.recording))
        XCTAssertEqual(recording.id, "5fb524f1-8cc8-4c04-a921-e34c0a911ea7")
        XCTAssertEqual(recording.title, "Smells Like Teen Spirit")
        XCTAssertEqual(recording.length, 301133)
        XCTAssertEqual(recording.lengthFormatted, "5:01")
        XCTAssertEqual(recording.firstReleaseDate, "1991-09-10")
        XCTAssertFalse(recording.video)
        XCTAssertEqual(recording.artistName, "Nirvana")
    }

    // MARK: - Label parsing

    func testParseLabel() throws {
        let label = MusicBrainzParser.label(try json(Fixture.label))
        XCTAssertEqual(label.id, "68803e28-86fe-4a95-985f-8e493795ab31")
        XCTAssertEqual(label.name, "DGC Records")
        XCTAssertEqual(label.type, "Original Production")
        XCTAssertEqual(label.country, "US")
        XCTAssertEqual(label.labelCode, 6406)
        XCTAssertEqual(label.area, "United States")
        XCTAssertEqual(label.lifeSpan.begin, "1990")
        XCTAssertFalse(label.lifeSpan.ended)
    }

    // MARK: - Search parsing

    func testParseReleaseSearch() throws {
        let results = MusicBrainzParser.searchResults(try json(Fixture.releaseSearch), type: .release)
        XCTAssertEqual(results.count, 108)
        XCTAssertEqual(results.offset, 0)
        XCTAssertEqual(results.results.count, 1)
        XCTAssertTrue(results.hasMore)

        let hit = try XCTUnwrap(results.results.first)
        XCTAssertEqual(hit.id, "f922ec87-4758-421d-a839-3193455345ff")
        XCTAssertEqual(hit.type, "release")
        XCTAssertEqual(hit.score, 100)
        XCTAssertEqual(hit.title, "Nevermind")
        XCTAssertEqual(hit.artistName, "Nirvana")
        XCTAssertEqual(hit.date, "1991-09-24")
        XCTAssertEqual(hit.country, "US")
    }

    func testParseArtistSearch() throws {
        let results = MusicBrainzParser.searchResults(try json(Fixture.artistSearch), type: .artist)
        XCTAssertEqual(results.count, 93)
        let hit = try XCTUnwrap(results.results.first)
        XCTAssertEqual(hit.type, "artist")
        XCTAssertEqual(hit.title, "Nirvana")          // artist "name" maps to title
        XCTAssertEqual(hit.sortName, "Nirvana")
        XCTAssertEqual(hit.disambiguation, "1980s–1990s US grunge band")
    }

    // MARK: - Combined artist credits

    func testCombinedArtistCreditsHonourJoinPhrases() {
        let credits = [
            MBArtistCredit(name: "Queen", joinPhrase: " & ", artistID: nil, artistName: nil, sortName: nil, disambiguation: nil),
            MBArtistCredit(name: "David Bowie", joinPhrase: nil, artistID: nil, artistName: nil, sortName: nil, disambiguation: nil)
        ]
        XCTAssertEqual(MBArtistCredit.combined(credits), "Queen & David Bowie")
    }

    // MARK: - Input validation

    func testLookupRejectsInvalidMBID() async {
        do {
            _ = try await MusicBrainzMetadata.release("not-a-uuid")
            XCTFail("Expected invalidInput")
        } catch MusicBrainzMetadataError.invalidInput {
            // expected
        } catch {
            XCTFail("Expected invalidInput, got \(error)")
        }
    }

    func testSearchRejectsEmptyQuery() async {
        do {
            _ = try await MusicBrainzMetadata.search("   ", type: .artist)
            XCTFail("Expected invalidInput")
        } catch MusicBrainzMetadataError.invalidInput {
            // expected
        } catch {
            XCTFail("Expected invalidInput, got \(error)")
        }
    }

    // MARK: - Live tests

    /// Keyless live coverage: a real search + real lookups end to end.
    /// Paced with sleeps to respect the ~1 req/sec limit.
    func testLiveSearchAndLookups() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["MUSICBRAINZ_LIVE_TESTS"] == "1",
                          "Set MUSICBRAINZ_LIVE_TESTS=1 to run.")
        let printOut = ProcessInfo.processInfo.environment["MUSICBRAINZ_PRINT"] == "1"

        // 1) Search for a release.
        let search = try await MusicBrainzMetadata.search(
            "nevermind AND artist:nirvana", type: .release, limit: 3
        )
        XCTAssertGreaterThan(search.count, 0)
        let first = try XCTUnwrap(search.results.first)
        XCTAssertFalse(first.title.isEmpty)
        try await Self.pace()

        // 2) Lookup a known release (tracklist + labels + Discogs URL).
        let release = try await MusicBrainzMetadata.release("b35c70b3-15f1-4792-a3d1-31645bde4db8")
        XCTAssertEqual(release.title, "Nevermind")
        XCTAssertEqual(release.artistName, "Nirvana")
        XCTAssertGreaterThan(release.trackCount, 0)
        try await Self.pace()

        // 3) Lookup the artist (aliases + Discogs URL cross-reference).
        let artist = try await MusicBrainzMetadata.artist("5b11f4ce-a62d-471e-81fc-a69a8278c7da")
        XCTAssertEqual(artist.name, "Nirvana")
        XCTAssertNotNil(artist.discogsURL)

        // The whole point of the change: streaming links reach the caller.
        XCTAssertGreaterThan(artist.links.count, 10, "url-rels are being dropped again")
        XCTAssertFalse(artist.links.streaming.isEmpty, "no streaming links survived parsing")
        XCTAssertNotNil(artist.links.spotifyURL)

        if printOut {
            print("=== live search ===")
            for hit in search.results.prefix(3) {
                print("• [\(hit.score)] \(hit.artistName ?? "?") – \(hit.title) (\(hit.date ?? "?")) [\(hit.country ?? "?")]")
            }
            print("=== live release lookup ===")
            print("\(release.artistName) – \(release.title) (\(release.date ?? "?")) · \(release.trackCount) tracks")
            print("labels: \(release.labels.compactMap(\.labelName).joined(separator: ", "))")
            print("Discogs: \(release.discogsURL ?? "—")")
            print("=== live artist lookup ===")
            print("\(artist.name) [\(artist.type ?? "?")] \(artist.lifeSpan.begin ?? "?")–\(artist.lifeSpan.end ?? "") · Discogs: \(artist.discogsURL ?? "—")")
            print("=== live streaming links (\(artist.links.count) relations total) ===")
            for link in artist.links.streaming {
                print("• \(link.service.map(\.rawValue) ?? "?")  [\(link.relationType)]  \(link.url)")
            }
        }
    }

    // MARK: - Helpers

    /// Sleeps ~1.1s to respect the MusicBrainz rate limit between live calls.
    private static func pace() async throws {
        try await Task.sleep(nanoseconds: 1_100_000_000)
    }

    private func json(_ string: String) throws -> [String: Any] {
        try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(string.utf8)) as? [String: Any])
    }
}

// MARK: - Fixtures (mirror verified MusicBrainz shapes)

private enum Fixture {
    static let release = """
    { "id": "b35c70b3-15f1-4792-a3d1-31645bde4db8", "title": "Nevermind",
      "date": "2011-10-04", "country": "US", "barcode": "602527779041",
      "status": "Official", "packaging": "None",
      "artist-credit": [
        { "name": "Nirvana", "joinphrase": "",
          "artist": { "id": "5b11f4ce-a62d-471e-81fc-a69a8278c7da", "name": "Nirvana", "sort-name": "Nirvana" } }
      ],
      "label-info": [
        { "catalog-number": "B0015884-01", "label": { "id": "68803e28-86fe-4a95-985f-8e493795ab31", "name": "DGC Records" } }
      ],
      "media": [
        { "position": 1, "format": "12\\" Vinyl", "track-count": 2,
          "tracks": [
            { "id": "675fe84a-0347-414d-9a81-7c7c599c6f8c", "title": "Smells Like Teen Spirit",
              "number": "A1", "position": 1, "length": null,
              "recording": { "id": "5fb524f1-8cc8-4c04-a921-e34c0a911ea7", "title": "Smells Like Teen Spirit", "length": 301133 } },
            { "id": "aaa11111-0000-0000-0000-000000000002", "title": "In Bloom",
              "number": "A2", "position": 2, "length": 254933,
              "recording": { "id": "bbb22222-0000-0000-0000-000000000003", "title": "In Bloom", "length": 254933 } }
          ]
        }
      ],
      "relations": [
        { "type": "discogs", "target-type": "url",
          "url": { "id": "04917d2c-9dbd-4b1a-9d4e-b469e97fee4c", "resource": "https://www.discogs.com/release/3183667" } }
      ]
    }
    """

    static let artist = """
    { "id": "5b11f4ce-a62d-471e-81fc-a69a8278c7da", "name": "Nirvana", "sort-name": "Nirvana",
      "type": "Group", "country": "US", "gender": null,
      "disambiguation": "1980s\\u20131990s US grunge band",
      "life-span": { "begin": "1987", "end": "1994-04-05", "ended": true },
      "aliases": [
        { "name": "Nirvana", "sort-name": "Nirvana", "locale": "en", "type": "Artist name", "primary": true },
        { "name": "Nirvana US", "sort-name": "Nirvana US", "locale": null, "type": null, "primary": null }
      ],
      "relations": [
        { "type": "allmusic", "target-type": "url", "url": { "resource": "https://www.allmusic.com/artist/mn0000357270" } },
        { "type": "discogs", "target-type": "url", "url": { "id": "81846eca-af41-43d0-bcae-b62dbf5cfa2f", "resource": "https://www.discogs.com/artist/125246" } },
        { "type": "free streaming", "target-type": "url", "url": { "resource": "https://open.spotify.com/artist/6olE6TJLqED3rqDCT0FyPh" } },
        { "type": "free streaming", "target-type": "url", "url": { "resource": "https://www.deezer.com/artist/604" } },
        { "type": "streaming", "target-type": "url", "url": { "resource": "https://music.apple.com/gb/artist/112018" } },
        { "type": "streaming", "target-type": "url", "url": { "resource": "https://tidal.com/artist/16928" } },
        { "type": "purchase for download", "target-type": "url", "url": { "resource": "https://music.apple.com/gb/artist/112018" } },
        { "type": "purchase for download", "target-type": "url", "url": { "resource": "https://www.beatport.com/artist/nirvana/12345" } },
        { "type": "youtube music", "target-type": "url", "url": { "resource": "https://music.youtube.com/channel/UCJ6QMrpAHNfMGjnCbnzWvEA" } },
        { "type": "social network", "target-type": "url", "url": { "resource": "https://twitter.com/nirvana" } },
        { "type": "official homepage", "target-type": "url", "url": { "resource": "https://www.nirvana.com/" } },
        { "type": "wikidata", "target-type": "url", "url": { "resource": "https://www.wikidata.org/wiki/Q11649" } },
        { "type": "artist", "target-type": "artist", "artist": { "id": "no-url-here", "name": "Kurt Cobain" } }
      ]
    }
    """

    static let releaseGroup = """
    { "id": "1b022e01-4da6-387b-8658-8678046e4cef", "title": "Nevermind",
      "primary-type": "Album", "secondary-types": [], "first-release-date": "1991-09-24",
      "artist-credit": [
        { "name": "Nirvana", "joinphrase": "",
          "artist": { "id": "5b11f4ce-a62d-471e-81fc-a69a8278c7da", "name": "Nirvana", "sort-name": "Nirvana" } }
      ],
      "relations": [
        { "type": "discogs", "target-type": "url", "url": { "resource": "https://www.discogs.com/master/13814" } }
      ]
    }
    """

    static let recording = """
    { "id": "5fb524f1-8cc8-4c04-a921-e34c0a911ea7", "title": "Smells Like Teen Spirit",
      "length": 301133, "first-release-date": "1991-09-10", "video": false,
      "artist-credit": [
        { "name": "Nirvana", "joinphrase": "",
          "artist": { "id": "5b11f4ce-a62d-471e-81fc-a69a8278c7da", "name": "Nirvana", "sort-name": "Nirvana" } }
      ]
    }
    """

    static let label = """
    { "id": "68803e28-86fe-4a95-985f-8e493795ab31", "name": "DGC Records", "sort-name": "DGC Records",
      "type": "Original Production", "country": "US", "label-code": 6406,
      "area": { "id": "489ce91b-6658-3307-9877-795b68554c98", "name": "United States" },
      "life-span": { "begin": "1990", "end": null, "ended": false },
      "relations": [
        { "type": "discogs", "target-type": "url", "url": { "resource": "https://www.discogs.com/label/165962" } }
      ]
    }
    """

    static let releaseSearch = """
    { "created": "2026-07-12T00:00:00.000Z", "count": 108, "offset": 0,
      "releases": [
        { "id": "f922ec87-4758-421d-a839-3193455345ff", "score": 100, "title": "Nevermind",
          "status": "Promotion", "date": "1991-09-24", "country": "US",
          "artist-credit": [
            { "name": "Nirvana", "artist": { "id": "5b11f4ce-a62d-471e-81fc-a69a8278c7da", "name": "Nirvana", "sort-name": "Nirvana" } }
          ],
          "track-count": 12 }
      ]
    }
    """

    static let artistSearch = """
    { "created": "2026-07-12T00:00:00.000Z", "count": 93, "offset": 0,
      "artists": [
        { "id": "5b11f4ce-a62d-471e-81fc-a69a8278c7da", "type": "Group", "score": 100,
          "name": "Nirvana", "sort-name": "Nirvana", "country": "US",
          "disambiguation": "1980s\\u20131990s US grunge band" }
      ]
    }
    """
}
