// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct ActivityRingsTests {
    @Test(arguments: [(0.4, 0.4), (-1.0, 0.0), (3.0, 1.0), (Double.nan, 0.0), (Double.infinity, 0.0)])
    func progressStaysInRange(progress: Double, expected: Double) {
        #expect(ActivityRingsMath.clamped(progress) == expected)
    }

    @Test func allRingsFitWhenThereIsRoom() {
        #expect(ActivityRingsMath.visibleCount(ringCount: 3, diameter: 240, lineWidth: 28, gap: 5) == 3)
    }

    @Test func ringsThatDoNotFitAreLeftOut() {
        #expect(ActivityRingsMath.visibleCount(ringCount: 20, diameter: 240, lineWidth: 28, gap: 5) == 3)
    }

    @Test(arguments: [(240.0, 0.0, 0.0), (0.0, 28.0, 5.0), (-10.0, 28.0, 5.0)])
    func invalidSizesDrawNoRings(diameter: Double, lineWidth: Double, gap: Double) {
        #expect(ActivityRingsMath.visibleCount(ringCount: 3, diameter: diameter, lineWidth: lineWidth, gap: gap) == 0)
    }

    @Test func theLastRingNeedsNoGapAfterIt() {
        #expect(ActivityRingsMath.visibleCount(ringCount: 1, diameter: 60, lineWidth: 28, gap: 5) == 1)
    }

    @Test func aRingThatOverflowsTheCenterIsStillLeftOut() {
        #expect(ActivityRingsMath.visibleCount(ringCount: 2, diameter: 60, lineWidth: 28, gap: 5) == 1)
    }
}
