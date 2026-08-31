//
//  SupportTests.swift
//  MusicBrainzMetadataTests
//
//  Created by David Sherlock on 2026.
//
//  The classification tables and length rule pinned directly.
//

import XCTest
@testable import MusicBrainzMetadata

final class SupportTests: XCTestCase {

    func testServiceByHost() {
        XCTAssertEqual(LinkClassification.service(forHost: "open.spotify.com"), .spotify)
        XCTAssertEqual(LinkClassification.service(forHost: "music.amazon.co.uk"), .amazonMusic,
                       "regional Amazon hosts match by prefix")
        XCTAssertEqual(LinkClassification.service(forHost: "www.tidal.com"), .tidal)
        XCTAssertNil(LinkClassification.service(forHost: "fakediscogs.com"),
                     "a host merely ending in a service name is not that service")
        XCTAssertNil(LinkClassification.service(forHost: "example.com"))
    }

    func testCategoryByRelationType() {
        XCTAssertEqual(LinkClassification.category(forRelationType: "Purchase for Download"), .purchase)
        XCTAssertEqual(LinkClassification.category(forRelationType: "free streaming"), .streaming)
        XCTAssertEqual(LinkClassification.category(forRelationType: "something new"), .other)
    }

    func testTrackLengthNeverFoldsIntoHours() {
        XCTAssertEqual(Formatting.trackLength(ms: 245_000), "4:05")
        XCTAssertEqual(Formatting.trackLength(ms: 65 * 60 * 1000), "65:00")
    }
}
