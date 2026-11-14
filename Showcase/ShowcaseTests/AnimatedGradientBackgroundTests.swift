// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct AnimatedGradientBackgroundTests {
    @Test func positivePositionsWrapAroundThePalette() {
        #expect(AnimatedGradientBackgroundMath.index(at: 5.5, count: 4) == 1)
    }

    @Test(arguments: [(-0.2, 3), (-4.5, 3), (-4, 0), (-1, 3)] as [(Double, Int)])
    func negativePositionsStayInThePalette(position: Double, expected: Int) {
        #expect(AnimatedGradientBackgroundMath.index(at: position, count: 4) == expected)
    }
}
