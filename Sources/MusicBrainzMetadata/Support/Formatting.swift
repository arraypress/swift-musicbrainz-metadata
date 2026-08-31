//
//  Formatting.swift
//  MusicBrainzMetadata
//
//  Created by David Sherlock on 2026.
//
//  Track lengths as `m:ss`, minutes never folding into hours — the same
//  rule lived twice, once on recordings and once on tracks; now it lives
//  here, pinned directly.
//

import Foundation

/// Presentation formatting for derived, human-readable strings.
enum Formatting {

    /// Milliseconds as `"m:ss"`, minutes unbounded.
    static func trackLength(ms: Int) -> String {
        let totalSeconds = ms / 1000
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}
