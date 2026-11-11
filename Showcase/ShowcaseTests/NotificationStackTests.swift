// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import CoreGraphics
import Testing
@testable import Showcase

struct NotificationStackTests {
    private typealias Math = NotificationStackMath
    private let heights: [CGFloat] = [70, 70, 70, 70]

    @Test func collapsedCardsPeekUnderTheFirst() {
        let tops = Math.tops(heights: heights, spacing: 10, peek: 8, progress: 0)

        #expect(tops == [0, 8, 16, 16])
    }

    @Test func expandedCardsFollowOneAnother() {
        let tops = Math.tops(heights: heights, spacing: 10, peek: 8, progress: 1)

        #expect(tops == [0, 80, 160, 240])
    }

    @Test func aTallerCardBehindKeepsItsBottomEdgeInLine() {
        let tops = Math.tops(heights: [70, 100], spacing: 10, peek: 8, progress: 0)

        #expect(tops == [0, -22])
    }

    @Test func theHeightGoesFromThePileToTheColumn() {
        #expect(Math.height(heights: heights, spacing: 10, peek: 8, progress: 0) == 86)
        #expect(Math.height(heights: heights, spacing: 10, peek: 8, progress: 1) == 310)
        #expect(Math.height(heights: heights, spacing: 10, peek: 8, progress: 0.5) == 198)
    }

    @Test func oneCardIsTheSameOpenOrClosed() {
        #expect(Math.height(heights: [70], spacing: 10, peek: 8, progress: 0) == 70)
        #expect(Math.height(heights: [70], spacing: 10, peek: 8, progress: 1) == 70)
    }

    @Test func noCardsTakeNoRoom() {
        #expect(Math.tops(heights: [], spacing: 10, peek: 8, progress: 0).isEmpty)
        #expect(Math.height(heights: [], spacing: 10, peek: 8, progress: 1) == 0)
    }

    @Test func cardsBehindAreSmallerOnlyWhileCollapsed() {
        #expect(Math.scale(depth: 0, progress: 0) == 1)
        #expect(abs(Math.scale(depth: 1, progress: 0) - 0.94) < 0.000_001)
        #expect(Math.scale(depth: 9, progress: 0) == Math.scale(depth: 2, progress: 0))
        #expect(Math.scale(depth: 2, progress: 1) == 1)
    }
}
