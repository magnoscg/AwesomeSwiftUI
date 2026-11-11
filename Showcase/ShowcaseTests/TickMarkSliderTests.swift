// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct TickMarkSliderTests {
    @Test func theSliderSettlesOnTheClosestMark() {
        #expect(TickMarkSliderMath.nearestTick(to: 1.2, in: [0.5, 1, 1.5, 2]) == 1)
        #expect(TickMarkSliderMath.nearestTick(to: 1.3, in: [0.5, 1, 1.5, 2]) == 1.5)
        #expect(TickMarkSliderMath.nearestTick(to: 9, in: [0.5, 1, 1.5, 2]) == 2)
    }

    @Test func aValueOnAMarkStaysThere() {
        #expect(TickMarkSliderMath.nearestTick(to: 1.5, in: [0.5, 1, 1.5, 2]) == 1.5)
    }

    @Test func noMarksGiveNothingToSettleOn() {
        #expect(TickMarkSliderMath.nearestTick(to: 1, in: []) == nil)
    }

    @Test func marksOutsideTheRangeAreLeftOut() {
        #expect(TickMarkSliderMath.ticks([-1, 0, 0.5, 1, 3], in: 0...1) == [0, 0.5, 1])
    }

    @Test func marksComeOutInOrderAndOnce() {
        #expect(TickMarkSliderMath.ticks([1, 0.5, 1, 0], in: 0...1) == [0, 0.5, 1])
        #expect(TickMarkSliderMath.ticks([.nan, 0.5], in: 0...1) == [0.5])
    }
}
