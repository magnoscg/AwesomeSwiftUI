// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import CoreGraphics
import Testing
@testable import Showcase

struct ColorRevealImageTests {
    @Test func theMiddleOfTheViewportHasFullColor() {
        #expect(ColorRevealImageMath.saturation(distanceFromCenter: 0, viewportHeight: 800) == 1)
    }

    @Test func farFromTheMiddleHasNoColor() {
        #expect(ColorRevealImageMath.saturation(distanceFromCenter: 600, viewportHeight: 800) == 0)
        #expect(ColorRevealImageMath.saturation(distanceFromCenter: -600, viewportHeight: 800) == 0)
    }

    @Test func colorFadesInBetween() {
        let saturation = ColorRevealImageMath.saturation(distanceFromCenter: 216, viewportHeight: 800)

        #expect(abs(saturation - 0.5) < 0.001)
    }

    @Test func noViewportMeansNoColor() {
        #expect(ColorRevealImageMath.saturation(distanceFromCenter: 0, viewportHeight: 0) == 0)
        #expect(ColorRevealImageMath.saturation(distanceFromCenter: .nan, viewportHeight: 800) == 0)
    }
}
