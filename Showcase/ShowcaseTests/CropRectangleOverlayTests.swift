// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import CoreGraphics
import Testing
@testable import Showcase

struct CropRectangleOverlayTests {
    private let rect = CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)

    @Test func aCornerMovesTwoEdges() {
        let result = CropRectangleOverlayHandle.topLeft.adjusting(rect, by: CGSize(width: 0.125, height: -0.125), minimumSide: 0.1)

        #expect(result == CGRect(x: 0.375, y: 0.125, width: 0.375, height: 0.625))
    }

    @Test func anEdgeMovesOnlyItself() {
        let result = CropRectangleOverlayHandle.right.adjusting(rect, by: CGSize(width: 0.125, height: 0.2), minimumSide: 0.1)

        #expect(result == CGRect(x: 0.25, y: 0.25, width: 0.625, height: 0.5))
    }

    @Test func aHandleCannotLeaveTheImage() {
        let result = CropRectangleOverlayHandle.bottomRight.adjusting(rect, by: CGSize(width: 9, height: 9), minimumSide: 0.1)

        #expect(result.maxX == 1)
        #expect(result.maxY == 1)
    }

    @Test func aHandleCannotCollapseTheFrame() {
        let result = CropRectangleOverlayHandle.left.adjusting(rect, by: CGSize(width: 9, height: 0), minimumSide: 0.25)

        #expect(result.width == 0.25)
        #expect(result.maxX == 0.75)
    }

    @Test func theBodyKeepsItsSizeAndStaysInside() {
        let result = CropRectangleOverlayHandle.body.adjusting(rect, by: CGSize(width: -9, height: 9), minimumSide: 0.1)

        #expect(result == CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5))
    }

    @Test func aHugeMinimumStaysInsideTheImage() {
        let result = CropRectangleOverlayHandle.top.adjusting(rect, by: .zero, minimumSide: 50)

        #expect(result.minY >= 0)
        #expect(result.height >= 0)
    }

    @Test func invalidRectsBecomeTheWholeImage() {
        let unit = CGRect(x: 0, y: 0, width: 1, height: 1)

        #expect(CropRectangleOverlayHandle.sanitized(.zero) == unit)
        #expect(CropRectangleOverlayHandle.sanitized(CGRect(x: 4, y: 4, width: 1, height: 1)) == unit)
    }

    @Test func outOfRangeRectsAreCut() {
        let result = CropRectangleOverlayHandle.sanitized(CGRect(x: 0.5, y: -1, width: 2, height: 2))

        #expect(result == CGRect(x: 0.5, y: 0, width: 0.5, height: 1))
    }
}
