// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct RulerScrollPickerTests {
    @Test func countsEveryStepIncludingBothEnds() {
        #expect(RulerScrollPickerScale(range: 40...120, step: 0.5).tickCount == 161)
        #expect(RulerScrollPickerScale(range: 5...5, step: 1).tickCount == 1)
    }

    @Test func invalidStepsFallBackToOne() {
        #expect(RulerScrollPickerScale(range: 0...10, step: 0).tickCount == 11)
        #expect(RulerScrollPickerScale(range: 0...10, step: -2).tickCount == 11)
        #expect(RulerScrollPickerScale(range: 0...10, step: .nan).tickCount == 11)
    }

    @Test func hugeRangesAreCapped() {
        let scale = RulerScrollPickerScale(range: 0...1e15, step: 0.001)

        #expect(scale.tickCount == RulerScrollPickerScale.maximumTickCount)
    }

    @Test func valuesStayInsideTheScale() {
        let scale = RulerScrollPickerScale(range: 10...20, step: 2)

        #expect(scale.value(at: 2) == 14)
        #expect(scale.value(at: -5) == 10)
        #expect(scale.value(at: .max) == 20)
    }

    @Test func valuesRoundToTheNearestTick() {
        let scale = RulerScrollPickerScale(range: 0...10, step: 1)

        #expect(scale.index(for: 3.6) == 4)
        #expect(scale.index(for: -50) == 0)
        #expect(scale.index(for: 1e300) == 10)
        #expect(scale.index(for: .nan) == 0)
    }

    @Test func offsetsRoundToTheNearestTick() {
        let scale = RulerScrollPickerScale(range: 0...10, step: 1)

        #expect(scale.index(forOffset: 40, spacing: 12) == 3)
        #expect(scale.index(forOffset: -30, spacing: 12) == 0)
        #expect(scale.index(forOffset: 9_000, spacing: 12) == 10)
        #expect(scale.index(forOffset: 40, spacing: 0) == 0)
    }

    @Test func aDecimalStepKeepsTheLastValue() {
        #expect(RulerScrollPickerScale(range: 0...0.3, step: 0.1).tickCount == 4)
    }

    @Test func aRangeThatStopsBetweenStepsStillRoundsDown() {
        #expect(RulerScrollPickerScale(range: 0...0.35, step: 0.1).tickCount == 4)
    }
}
