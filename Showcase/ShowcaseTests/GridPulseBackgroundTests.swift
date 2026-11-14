// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct GridPulseBackgroundTests {
    @Test func dotsFillHalfTheExtentOnEachSide() {
        #expect(GridPulseBackgroundMath.dotsPerSide(extent: 260, spacing: 26) == 6)
    }

    @Test func anEmptyExtentKeepsTheCenterLine() {
        #expect(GridPulseBackgroundMath.dotsPerSide(extent: 0, spacing: 26) == 1)
    }

    @Test(arguments: [0, -26, .infinity, .nan] as [Double])
    func spacingThatCannotLayOutAGridGivesNoDots(spacing: Double) {
        #expect(GridPulseBackgroundMath.dotsPerSide(extent: 260, spacing: spacing) == nil)
    }
}
