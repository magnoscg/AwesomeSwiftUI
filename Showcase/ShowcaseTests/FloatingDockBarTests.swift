// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import CoreGraphics
import Testing
@testable import Showcase

struct FloatingDockBarTests {
    @Test func isLargestRightUnderTheFinger() {
        #expect(FloatingDockBarMath.scale(distance: 0, spread: 100, maxScale: 1.6) == 1.6)
    }

    @Test(arguments: [CGFloat(100), 250, -400])
    func isNormalSizeOutsideTheSpread(distance: CGFloat) {
        #expect(FloatingDockBarMath.scale(distance: distance, spread: 100, maxScale: 1.6) == 1)
    }

    @Test func fallsOffSymmetrically() {
        let left = FloatingDockBarMath.scale(distance: -40, spread: 100, maxScale: 1.6)
        let right = FloatingDockBarMath.scale(distance: 40, spread: 100, maxScale: 1.6)

        #expect(left == right)
        #expect(left > 1 && left < 1.6)
    }

    @Test func aZeroSpreadDoesNotDivideByZero() {
        #expect(FloatingDockBarMath.scale(distance: 0, spread: 0, maxScale: 1.6) == 1)
    }

    @Test func aMaxScaleBelowOneDoesNotShrinkIcons() {
        #expect(FloatingDockBarMath.scale(distance: 0, spread: 100, maxScale: 0.5) == 1)
    }

    @Test func keepsThePreferredSizeWhenItFits() {
        #expect(FloatingDockBarMath.iconSize(preferred: 56, available: 400, count: 5, spacing: 12, padding: 12) == 56)
    }

    @Test func shrinksToFitManyIcons() {
        let size = FloatingDockBarMath.iconSize(preferred: 56, available: 400, count: 8, spacing: 12, padding: 12)

        #expect(size == CGFloat(400 - 24 - 84) / 8)
    }

    @Test func noIconsKeepsTheSizeValid() {
        #expect(FloatingDockBarMath.iconSize(preferred: 56, available: 0, count: 0, spacing: 12, padding: 12) == 56)
    }

    @Test func neverCollapsesToNothing() {
        #expect(FloatingDockBarMath.iconSize(preferred: 56, available: 100, count: 50, spacing: 12, padding: 12) == 20)
    }

    @Test func centersStepByIconAndSpacing() {
        #expect(FloatingDockBarMath.centerX(index: 2, iconSize: 50, spacing: 10) == 145)
    }
}
