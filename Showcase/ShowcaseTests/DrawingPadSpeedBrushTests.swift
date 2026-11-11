// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct DrawingPadSpeedBrushTests {
    @Test func aStillFingerDrawsTheThickestLine() {
        #expect(DrawingPadSpeedBrushMath.width(speed: 0, thin: 2, thick: 16, fullSpeed: 1000) == 16)
    }

    @Test func halfSpeedDrawsHalfway() {
        #expect(DrawingPadSpeedBrushMath.width(speed: 500, thin: 2, thick: 16, fullSpeed: 1000) == 9)
    }

    @Test func speedsPastTheLimitStayAtTheThinnestLine() {
        #expect(DrawingPadSpeedBrushMath.width(speed: 9_000, thin: 2, thick: 16, fullSpeed: 1000) == 2)
    }

    @Test func invalidInputsStayDrawable() {
        #expect(DrawingPadSpeedBrushMath.width(speed: 100, thin: 2, thick: 16, fullSpeed: 0) == 16)
        #expect(DrawingPadSpeedBrushMath.width(speed: .infinity, thin: 2, thick: 16, fullSpeed: 1000) == 16)
        #expect(DrawingPadSpeedBrushMath.width(speed: 9_000, thin: -4, thick: 16, fullSpeed: 1000) == 0.5)
        #expect(DrawingPadSpeedBrushMath.width(speed: 0, thin: 8, thick: 2, fullSpeed: 1000) == 8)
    }

    @Test func smoothingMovesPartOfTheWay() {
        #expect(DrawingPadSpeedBrushMath.smoothed(from: 10, to: 20, factor: 0.5) == 15)
        #expect(DrawingPadSpeedBrushMath.smoothed(from: 10, to: 20, factor: 7) == 20)
    }
}
