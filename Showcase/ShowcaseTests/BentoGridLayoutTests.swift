// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import CoreGraphics
import Testing
@testable import Showcase

struct BentoGridLayoutTests {
    private func frames(_ spans: [(Int, Int)], columns: Int = 4) -> [CGRect] {
        BentoGridLayoutMath.frames(
            spans: spans.map { BentoGridLayoutSpan(columns: $0.0, rows: $0.1) },
            columns: columns,
            width: 412,
            rowHeight: 100,
            spacing: 12
        )
    }

    @Test func singleTileUsesOneCell() {
        #expect(frames([(1, 1)]) == [CGRect(x: 0, y: 0, width: 94, height: 100)])
    }

    @Test func spanningIncludesTheGapsItCovers() {
        #expect(frames([(2, 2)]) == [CGRect(x: 0, y: 0, width: 200, height: 212)])
    }

    @Test func tilesFlowAcrossThenDown() {
        let result = frames([(2, 1), (2, 1), (1, 1)])

        #expect(result[1].origin == CGPoint(x: 212, y: 0))
        #expect(result[2].origin == CGPoint(x: 0, y: 112))
    }

    @Test func aSmallTileFillsTheHoleBesideATallOne() {
        let result = frames([(2, 2), (3, 1), (2, 1)])

        #expect(result[1].origin == CGPoint(x: 0, y: 224))
        #expect(result[2].origin == CGPoint(x: 212, y: 0))
    }

    @Test func aSpanWiderThanTheGridIsCapped() {
        #expect(frames([(9, 1)]) == [CGRect(x: 0, y: 0, width: 412, height: 100)])
    }

    @Test func spansBelowOneBecomeOne() {
        #expect(frames([(0, -3)]) == [CGRect(x: 0, y: 0, width: 94, height: 100)])
    }

    @Test func tilesNeverOverlap() {
        let result = frames([(2, 2), (1, 1), (1, 2), (3, 1), (1, 1), (4, 1), (2, 3), (1, 1)])

        for (index, frame) in result.enumerated() {
            for other in result[(index + 1)...] {
                #expect(!frame.intersects(other))
            }
        }
    }

    @Test func noColumnsGivesNoFrames() {
        #expect(frames([(1, 1)], columns: 0).isEmpty)
    }
}
