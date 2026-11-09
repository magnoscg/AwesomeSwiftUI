// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import CoreGraphics
import Testing
@testable import Showcase

struct NotchedTabBarTests {
    @Test func centersAreEvenlySpaced() {
        let centers = (0..<4).map { NotchedTabBarMath.centerX(index: $0, count: 4, width: 420, inset: 10) }

        #expect(centers == [60, 160, 260, 360])
    }

    @Test(arguments: [-5, 99, Int.max, Int.min])
    func outOfRangeIndexesStayOnABar(index: Int) {
        let center = NotchedTabBarMath.centerX(index: index, count: 3, width: 300, inset: 0)

        #expect((0...300).contains(center))
    }

    @Test func noTabsCentersTheNotch() {
        #expect(NotchedTabBarMath.centerX(index: 0, count: 0, width: 300, inset: 10) == 150)
    }

    @Test func aZeroWidthBarDoesNotGoNegative() {
        #expect(NotchedTabBarMath.centerX(index: 2, count: 3, width: 0, inset: 10) == 0)
    }

    @Test func aCenteredNotchKeepsItsSize() {
        #expect(NotchedTabBarMath.halfSpan(centerX: 200, width: 400, corner: 26, desired: 48) == 48)
    }

    @Test func aNotchNearTheEdgeStopsAtTheCorner() {
        #expect(NotchedTabBarMath.halfSpan(centerX: 60, width: 400, corner: 26, desired: 48) == 34)
    }

    @Test func aNotchInsideACornerCollapses() {
        #expect(NotchedTabBarMath.halfSpan(centerX: 10, width: 400, corner: 26, desired: 48) == 0)
    }
}
