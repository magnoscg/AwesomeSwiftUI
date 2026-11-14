// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import CoreGraphics
import Testing
@testable import Showcase

struct PlayPauseMorphButtonTests {
    @Test func playIsATriangleCutInTwo() throws {
        let pieces = PlayPauseMorphButtonShape(progress: 0).pieces()
        let right = try #require(pieces.last)

        #expect(pieces.count == 2)
        #expect(right[1] == right[2])
    }

    @Test func pauseIsTwoSeparateBars() throws {
        let pieces = PlayPauseMorphButtonShape(progress: 1).pieces()
        let left = try #require(pieces.first)
        let right = try #require(pieces.last)

        #expect(left[1].x < right[0].x)
        #expect(abs(left[0].y - left[1].y) < 0.000_001)
        #expect(abs(right[2].y - right[3].y) < 0.000_001)
    }

    @Test func halfwayIsTheMidpoint() throws {
        let start = try #require(PlayPauseMorphButtonShape(progress: 0).pieces().first?.first)
        let end = try #require(PlayPauseMorphButtonShape(progress: 1).pieces().first?.first)
        let middle = try #require(PlayPauseMorphButtonShape(progress: 0.5).pieces().first?.first)

        #expect(abs(middle.x - (start.x + end.x) / 2) < 0.000_001)
        #expect(abs(middle.y - (start.y + end.y) / 2) < 0.000_001)
    }

    @Test func progressOutsideTheRangeIsClamped() {
        #expect(PlayPauseMorphButtonShape(progress: 1.4).pieces() == PlayPauseMorphButtonShape(progress: 1).pieces())
        #expect(PlayPauseMorphButtonShape(progress: -0.3).pieces() == PlayPauseMorphButtonShape(progress: 0).pieces())
    }
}
