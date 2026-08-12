//
//  ClientBehaviourTests.swift
//  MusicBrainzMetadata
//
//  How the client reacts to what MusicBrainz sends back, without sending
//  anything. A stub protocol answers on behalf of the service, so the status
//  handling and the retry are exercised offline — which matters here more than
//  most places, because the behaviour under test is what happens when the real
//  service is having a bad minute.
//
//  Created by David Sherlock on 2026.
//

import XCTest
@testable import MusicBrainzMetadata

/// Answers requests with a scripted sequence of responses.
final class StubProtocol: URLProtocol {

    struct Reply {
        let status: Int
        let body: String
        var headers: [String: String] = [:]
    }

    nonisolated(unsafe) private static var replies: [Reply] = []
    nonisolated(unsafe) private(set) static var requestCount = 0
    private static let lock = NSLock()

    static func script(_ replies: [Reply]) {
        lock.lock(); defer { lock.unlock() }
        Self.replies = replies
        Self.requestCount = 0
    }

    private static func next() -> Reply {
        lock.lock(); defer { lock.unlock() }
        requestCount += 1
        // The last reply repeats, so a test only has to script the part that
        // changes.
        return replies.count > 1 ? replies.removeFirst() : (replies.first ?? Reply(status: 200, body: "{}"))
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "musicbrainz.org"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let reply = StubProtocol.next()
        let response = HTTPURLResponse(
            url: request.url!, statusCode: reply.status,
            httpVersion: "HTTP/1.1", headerFields: reply.headers
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(reply.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class ClientBehaviourTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(StubProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(StubProtocol.self)
        super.tearDown()
    }

    private var noRetry: MusicBrainzMetadata.Configuration {
        MusicBrainzMetadata.Configuration(userAgent: "tests/1.0", retryLimit: 0)
    }

    // MARK: - Status handling

    /// A 400 is a request MusicBrainz could not parse. Reporting it as "not
    /// found" sends somebody looking for a record that was never the problem —
    /// and MusicBrainz really does answer 400 for some inputs that look like
    /// MBIDs, the all-zero UUID among them.
    func testABadRequestIsNotAMissingRecord() async {
        StubProtocol.script([.init(
            status: 400,
            body: #"{"error":"Invalid mbid."}"#
        )])

        do {
            _ = try await MusicBrainzMetadata.artist(
                "00000000-0000-0000-0000-000000000000", configuration: noRetry
            )
            XCTFail("a 400 must throw")
        } catch let error as MusicBrainzMetadataError {
            guard case .invalidInput(let message) = error else {
                return XCTFail("expected invalidInput, got \(error)")
            }
            XCTAssertEqual(message, "Invalid mbid.", "MusicBrainz's own wording is the useful part")
        } catch {
            XCTFail("unexpected \(error)")
        }
    }

    func testAMissingRecordIsNotFound() async {
        StubProtocol.script([.init(status: 404, body: #"{"error":"Not Found"}"#)])

        do {
            _ = try await MusicBrainzMetadata.artist(
                "a1b2c3d4-e5f6-4789-abcd-ef0123456789", configuration: noRetry
            )
            XCTFail("a 404 must throw")
        } catch let error as MusicBrainzMetadataError {
            XCTAssertEqual(error, .notFound)
        } catch {
            XCTFail("unexpected \(error)")
        }
    }

    func testRetryAfterIsCarriedOnTheError() async {
        StubProtocol.script([.init(
            status: 503,
            body: #"{"error":"busy"}"#,
            headers: ["Retry-After": "7"]
        )])

        do {
            _ = try await MusicBrainzMetadata.artist(
                "a1b2c3d4-e5f6-4789-abcd-ef0123456789", configuration: noRetry
            )
            XCTFail("a 503 with no retries left must throw")
        } catch let error as MusicBrainzMetadataError {
            XCTAssertEqual(error, .rateLimited(7))
        } catch {
            XCTFail("unexpected \(error)")
        }
    }

    // MARK: - Retrying

    /// MusicBrainz answers 503 with "the web server is currently busy, please
    /// try again later" — and it means it. Its meter is a bucket shared by
    /// every caller, so this arrives whatever one client does. Giving up on
    /// the first one made the library fail a few times an hour for reasons its
    /// caller could neither see nor influence.
    func testATransientBusyResponseIsRetried() async throws {
        StubProtocol.script([
            .init(status: 503, body: #"{"error":"The MusicBrainz web server is currently busy."}"#),
            .init(status: 200, body: #"{"id":"a1b2c3d4-e5f6-4789-abcd-ef0123456789","name":"Nirvana"}"#),
        ])

        let artist = try await MusicBrainzMetadata.artist(
            "a1b2c3d4-e5f6-4789-abcd-ef0123456789",
            configuration: .init(userAgent: "tests/1.0", retryLimit: 2)
        )
        XCTAssertEqual(artist.name, "Nirvana")
        XCTAssertEqual(StubProtocol.requestCount, 2, "one failure, one retry")
    }

    func testRetryingStopsAtTheLimit() async {
        StubProtocol.script([.init(status: 503, body: #"{"error":"busy"}"#)])

        do {
            _ = try await MusicBrainzMetadata.artist(
                "a1b2c3d4-e5f6-4789-abcd-ef0123456789",
                configuration: .init(userAgent: "tests/1.0", retryLimit: 2)
            )
            XCTFail("a permanent 503 must eventually throw")
        } catch {
            XCTAssertEqual(StubProtocol.requestCount, 3, "the first try plus two retries")
        }
    }

    /// A 404 will still be a 404 next time. Repeating a request that was
    /// refused on its merits is how a client earns a longer ban.
    func testNothingButABusyResponseIsRetried() async {
        StubProtocol.script([.init(status: 404, body: #"{"error":"Not Found"}"#)])

        do {
            _ = try await MusicBrainzMetadata.artist(
                "a1b2c3d4-e5f6-4789-abcd-ef0123456789",
                configuration: .init(userAgent: "tests/1.0", retryLimit: 2)
            )
            XCTFail("a 404 must throw")
        } catch {
            XCTAssertEqual(StubProtocol.requestCount, 1, "a 404 is asked once")
        }
    }

    // MARK: - Before the network

    /// Caught client-side, so a typo costs nothing and does not count against
    /// a limit shared with everybody else.
    func testSomethingThatIsNotAUUIDNeverLeavesTheProcess() async {
        StubProtocol.script([.init(status: 200, body: "{}")])

        do {
            _ = try await MusicBrainzMetadata.artist("nirvana", configuration: noRetry)
            XCTFail("a non-UUID must throw")
        } catch let error as MusicBrainzMetadataError {
            guard case .invalidInput(let message) = error else {
                return XCTFail("expected invalidInput, got \(error)")
            }
            XCTAssertTrue(message.contains("not an MBID"), message)
            XCTAssertTrue(message.contains("UUID"), "say what one looks like: \(message)")
            XCTAssertEqual(StubProtocol.requestCount, 0, "nothing should have been sent")
        } catch {
            XCTFail("unexpected \(error)")
        }
    }

    func testAnEmptyQueryNeverLeavesTheProcess() async {
        StubProtocol.script([.init(status: 200, body: "{}")])

        do {
            _ = try await MusicBrainzMetadata.search("   ", type: .artist, configuration: noRetry)
            XCTFail("an empty query must throw")
        } catch {
            XCTAssertEqual(StubProtocol.requestCount, 0, "nothing should have been sent")
        }
    }
}
