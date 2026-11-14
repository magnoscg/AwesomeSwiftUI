// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import CoreGraphics
import Foundation
import Testing
@testable import Showcase

struct FlowFieldParticlesTests {
    private let size = CGSize(width: 402, height: 874)

    @Test(arguments: [-3.2, -1.0, 0, 0.25, 7.999, Double.infinity, Double.nan])
    func fractionStaysInUnitRange(value: Double) {
        let part = FlowFieldParticlesMath.fraction(value)

        #expect(part >= 0)
        #expect(part < 1)
    }

    @Test(arguments: [(-5, 0), (0, 0), (10, 10), (Int.max, 2_000)])
    func countIsClamped(count: Int, expected: Int) {
        #expect(FlowFieldParticlesMath.clampedCount(count) == expected)
    }

    @Test func aStreakKeepsOnlyItsTail() {
        let streak = FlowFieldParticlesMath.streak(index: 3, time: 2, size: size, steps: 24, trail: 8)

        #expect(streak.points.count == 9)
    }

    @Test func aTrailLongerThanTheStepsKeepsEveryStep() {
        let streak = FlowFieldParticlesMath.streak(index: 3, time: 2, size: size, steps: 4, trail: 20)

        #expect(streak.points.count == 5)
    }

    @Test(arguments: [CGSize.zero, CGSize(width: -10, height: 40), CGSize(width: 40, height: 0)])
    func anEmptyCanvasDrawsNothing(size: CGSize) {
        let streak = FlowFieldParticlesMath.streak(index: 1, time: 1, size: size)

        #expect(streak.points.isEmpty)
    }

    @Test func noStepsDrawNothing() {
        let streak = FlowFieldParticlesMath.streak(index: 1, time: 1, size: size, steps: 0)

        #expect(streak.points.isEmpty)
    }

    @Test func theSameInputGivesTheSameStreak() {
        let first = FlowFieldParticlesMath.streak(index: 12, time: 41.5, size: size)
        let second = FlowFieldParticlesMath.streak(index: 12, time: 41.5, size: size)

        #expect(first.points == second.points)
        #expect(first.opacity == second.opacity)
    }

    @Test(arguments: [0, 1, 17, 259, Int.max])
    func opacityIsAlwaysVisibleRange(index: Int) {
        let streak = FlowFieldParticlesMath.streak(index: index, time: 800_000_000, size: size)

        #expect(streak.opacity >= 0)
        #expect(streak.opacity <= 1)
        #expect(streak.points.allSatisfy { $0.x.isFinite && $0.y.isFinite })
    }
}
