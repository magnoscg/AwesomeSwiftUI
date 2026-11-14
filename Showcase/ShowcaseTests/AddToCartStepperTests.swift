// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct AddToCartStepperTests {
    @Test(arguments: [(0, 0), (-3, 0), (5, 5), (2_000_000, 1_000_000)])
    func theLimitAllowsZeroAndStaysInRange(maximum: Int, expected: Int) {
        #expect(AddToCartStepperMath.limit(maximum: maximum) == expected)
    }
}
