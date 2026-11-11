// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import CoreGraphics
import Testing
@testable import Showcase

struct PinchZoomViewTests {
    private let size = CGSize(width: 200, height: 400)

    @Test(arguments: [(0.5, 1.0), (1.0, 1.0), (2.5, 2.5), (4.0, 4.0), (9.0, 4.0)] as [(CGFloat, CGFloat)])
    func clampKeepsTheScaleInRange(value: CGFloat, expected: CGFloat) {
        #expect(PinchZoomViewMath.clamp(value, to: 1...4) == expected)
    }

    @Test func rubberBandFollowsInsideTheRange() {
        #expect(PinchZoomViewMath.rubberBand(2, in: 1...4) == 2)
    }

    @Test func rubberBandResistsBeyondEitherEnd() {
        #expect(PinchZoomViewMath.rubberBand(5, in: 1...4, resistance: 0.5) == 4.5)
        #expect(PinchZoomViewMath.rubberBand(0, in: 1...4, resistance: 0.5) == 0.5)
    }

    @Test func contentAtNormalSizeCannotMove() {
        #expect(PinchZoomViewMath.maxOffset(scale: 1, size: size) == .zero)
    }

    @Test func maxOffsetIsHalfTheExtraSize() {
        #expect(PinchZoomViewMath.maxOffset(scale: 2, size: size) == CGSize(width: 100, height: 200))
    }

    @Test func scaleBelowOneNeverGivesANegativeLimit() {
        #expect(PinchZoomViewMath.maxOffset(scale: 0.5, size: size) == .zero)
    }

    @Test func offsetInsideTheLimitIsKept() {
        let offset = CGSize(width: 40, height: -80)

        #expect(PinchZoomViewMath.clampedOffset(offset, scale: 2, size: size) == offset)
    }

    @Test func offsetPastTheLimitSpringsBackToTheEdge() {
        let clamped = PinchZoomViewMath.clampedOffset(CGSize(width: 500, height: -500), scale: 2, size: size)

        #expect(clamped == CGSize(width: 100, height: -200))
    }
}
