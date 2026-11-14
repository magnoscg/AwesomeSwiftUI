// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import CoreGraphics
import Testing
@testable import Showcase

struct FloatingActionMenuTests {
    @Test func itemsSpreadFromTheStartAngleToTheEndAngle() {
        let first = FloatingActionMenuMath.offset(index: 0, count: 3, radius: 100, startDegrees: 180, endDegrees: 270)
        let last = FloatingActionMenuMath.offset(index: 2, count: 3, radius: 100, startDegrees: 180, endDegrees: 270)

        #expect(abs(first.width + 100) < 0.001)
        #expect(abs(first.height) < 0.001)
        #expect(abs(last.width) < 0.001)
        #expect(abs(last.height + 100) < 0.001)
    }

    @Test func aSingleItemSitsInTheMiddleOfTheArc() {
        let offset = FloatingActionMenuMath.offset(index: 0, count: 1, radius: 100, startDegrees: 180, endDegrees: 270)

        #expect(offset.width < 0)
        #expect(abs(offset.width - offset.height) < 0.001)
    }

    @Test(arguments: [(0, 0), (3, 3), (-1, 3), (Int.max, 3)] as [(Int, Int)])
    func invalidIndexesStayInPlace(index: Int, count: Int) {
        #expect(FloatingActionMenuMath.offset(index: index, count: count, radius: 100, startDegrees: 180, endDegrees: 270) == .zero)
    }

    @Test func negativeRadiusCollapsesToTheCenter() {
        let offset = FloatingActionMenuMath.offset(index: 1, count: 3, radius: -50, startDegrees: 0, endDegrees: 90)

        #expect(offset == .zero)
    }

    @Test func aFewItemsKeepTheRadius() {
        #expect(FloatingActionMenuMath.fittedRadius(112, itemSize: 50, count: 4, startDegrees: 180, endDegrees: 270) == 112)
    }

    @Test func manyItemsWidenTheFanSoNeighboursDoNotOverlap() {
        let radius = FloatingActionMenuMath.fittedRadius(112, itemSize: 50, count: 10, startDegrees: 180, endDegrees: 270)
        let first = FloatingActionMenuMath.offset(index: 0, count: 10, radius: radius, startDegrees: 180, endDegrees: 270)
        let second = FloatingActionMenuMath.offset(index: 1, count: 10, radius: radius, startDegrees: 180, endDegrees: 270)

        #expect(hypot(first.width - second.width, first.height - second.height) >= 50)
    }

    @Test func aLongFanStopsAtTheEdgeOfTheScreen() {
        let center = CGPoint(x: 335, y: 700)
        let limit = FloatingActionMenuMath.radiusLimit(center: center, container: CGSize(width: 393, height: 852), inset: 33, count: 12, startDegrees: 180, endDegrees: 270)
        let radius = FloatingActionMenuMath.fittedRadius(112, itemSize: 50, count: 12, startDegrees: 180, endDegrees: 270, limit: limit)
        let leftmost = FloatingActionMenuMath.offset(index: 0, count: 12, radius: radius, startDegrees: 180, endDegrees: 270)

        #expect(center.x + leftmost.width - 25 >= 0)
    }

    @Test func theLimitCoversFansThatOpenRightAndDown() {
        let limit = FloatingActionMenuMath.radiusLimit(center: CGPoint(x: 60, y: 100), container: CGSize(width: 393, height: 852), inset: 33, count: 5, startDegrees: 0, endDegrees: 90)

        #expect(abs(limit - 300) < 0.001)
    }

    @Test func aTightContainerDoesNotShrinkTheBaseRadius() {
        #expect(FloatingActionMenuMath.fittedRadius(112, itemSize: 50, count: 12, startDegrees: 180, endDegrees: 270, limit: 40) == 112)
    }

    @Test func noSweepKeepsTheRadius() {
        #expect(FloatingActionMenuMath.fittedRadius(112, itemSize: 50, count: 5, startDegrees: 90, endDegrees: 90) == 112)
    }
}
