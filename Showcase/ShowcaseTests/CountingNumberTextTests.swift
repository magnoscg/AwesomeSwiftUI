// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct CountingNumberTextTests {
    @Test func aMidpointIsHalfWayThere() {
        #expect(CountingNumberTextMath.value(from: 10, to: 20, progress: 0.5) == 15)
    }

    @Test func theLastStepIsTheExactValue() {
        #expect(CountingNumberTextMath.value(from: 0, to: .max, progress: 1) == .max)
    }

    @Test func aValueThatRoundsPastTheLargestIntegerStaysInRange() {
        #expect(CountingNumberTextMath.value(from: .max, to: .max - 1, progress: 0.5) == .max)
    }

    @Test func roundingNearTheLimitStaysBetweenTheEndpoints() {
        #expect(CountingNumberTextMath.value(from: .max - 100, to: .max - 99, progress: 0.1) == .max - 99)
    }

    @Test func theWidestRangeDoesNotOverflow() {
        #expect(CountingNumberTextMath.value(from: .min, to: 0, progress: 0.5) == .min / 2)
        #expect(CountingNumberTextMath.value(from: .min, to: .max, progress: 0.5) == 0)
    }
}
