// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Testing
@testable import Showcase

struct IntelligenceGlowBorderTests {
    @Test func phaseWrapsEveryPeriod() {
        #expect(IntelligenceGlowBorderMath.phase(time: 9, period: 6) == 0.5)
        #expect(IntelligenceGlowBorderMath.phase(time: 12, period: 6) == 0)
    }

    @Test func invalidTimingStaysAtTheStart() {
        #expect(IntelligenceGlowBorderMath.phase(time: 9, period: 0) == 0)
        #expect(IntelligenceGlowBorderMath.phase(time: 9, period: -3) == 0)
        #expect(IntelligenceGlowBorderMath.phase(time: .infinity, period: 6) == 0)
    }

    @Test func aPositionBetweenTwoColorsBlendsThem() {
        let blend = IntelligenceGlowBorderMath.blend(at: 0.375, count: 4)

        #expect(blend.lower == 1)
        #expect(blend.upper == 2)
        #expect(blend.fraction == 0.5)
    }

    @Test func theLastColorBlendsBackIntoTheFirst() {
        let blend = IntelligenceGlowBorderMath.blend(at: 0.875, count: 4)

        #expect(blend.lower == 3)
        #expect(blend.upper == 0)
        #expect(blend.fraction == 0.5)
    }

    @Test func positionsOutsideTheLoopWrap() {
        let blend = IntelligenceGlowBorderMath.blend(at: -0.25, count: 4)

        #expect(blend.lower == 3)
        #expect(blend.upper == 0)
        #expect(blend.fraction == 0)
    }

    @Test func aSingleColorHasNothingToBlend() {
        let blend = IntelligenceGlowBorderMath.blend(at: 0.6, count: 1)

        #expect(blend.lower == 0)
        #expect(blend.upper == 0)
        #expect(blend.fraction == 0)
    }

    @Test func theMeshHasAPointForEveryColor() {
        let points = IntelligenceGlowBorderMath.points(phase: 0.3)

        #expect(points.count == IntelligenceGlowBorderMath.side * IntelligenceGlowBorderMath.side)
        #expect(Set(IntelligenceGlowBorderMath.perimeter).count == points.count - 1)
    }

    @Test(arguments: [0, 0.2, 0.55, 0.9])
    func cornersStayPutAndEveryPointStaysInside(phase: Double) {
        let points = IntelligenceGlowBorderMath.points(phase: phase)

        #expect(points[0] == SIMD2(0, 0))
        #expect(points[2] == SIMD2(1, 0))
        #expect(points[6] == SIMD2(0, 1))
        #expect(points[8] == SIMD2(1, 1))
        #expect(points.allSatisfy { (0...1).contains($0.x) && (0...1).contains($0.y) })
    }
}
