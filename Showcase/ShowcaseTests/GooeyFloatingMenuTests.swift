// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Foundation
import Testing
@testable import Showcase

struct GooeyFloatingMenuTests {
    private func isClose(_ first: Double, _ second: Double) -> Bool {
        abs(first - second) < 0.001
    }

    @Test func aSingleOptionGoesStraightUp() {
        let offset = GooeyFloatingMenuMath.offset(index: 0, count: 1, radius: 100)

        #expect(isClose(offset.width, 0))
        #expect(isClose(offset.height, -100))
    }

    @Test func theFanIsSymmetric() {
        let first = GooeyFloatingMenuMath.offset(index: 0, count: 3, radius: 100)
        let middle = GooeyFloatingMenuMath.offset(index: 1, count: 3, radius: 100)
        let last = GooeyFloatingMenuMath.offset(index: 2, count: 3, radius: 100)

        #expect(isClose(first.width, -last.width))
        #expect(isClose(first.height, last.height))
        #expect(isClose(middle.width, 0))
    }

    @Test(arguments: 0..<4) func everyOptionArrivesTogether(index: Int) {
        #expect(isClose(GooeyFloatingMenuMath.staggered(1, index: index, count: 4), 1))
        #expect(isClose(GooeyFloatingMenuMath.staggered(0, index: index, count: 4), 0))
    }

    @Test func laterOptionsLagBehind() {
        let first = GooeyFloatingMenuMath.staggered(0.3, index: 0, count: 4)
        let last = GooeyFloatingMenuMath.staggered(0.3, index: 3, count: 4)

        #expect(first > last)
        #expect(last == 0)
    }

    @Test(arguments: [4, 5]) func theOuterOptionsStayInsideANarrowContainer(count: Int) {
        let size = GooeyFloatingMenuMath.fittedButtonSize(81, availableWidth: 320)
        let outer = GooeyFloatingMenuMath.offset(index: 0, count: count, radius: size * 2.1)

        #expect(abs(outer.width) + size * 0.475 <= 160)
    }

    @Test(arguments: [320.0, 393.0]) func theDefaultSizeIsKeptOnAPhone(width: Double) {
        #expect(GooeyFloatingMenuMath.fittedButtonSize(64, availableWidth: width) == 64)
    }

    @Test(arguments: [0, 1]) func smallMenusAreNotDelayed(count: Int) {
        #expect(GooeyFloatingMenuMath.staggered(0.4, index: 0, count: count) == 0.4)
    }
}
