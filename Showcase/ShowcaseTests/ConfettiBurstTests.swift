// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Foundation
import Testing
@testable import Showcase

struct ConfettiBurstTests {
    private let motion = ConfettiBurstMotion()

    @Test(arguments: [-1.2, 0, 0.8])
    func startsAtTheOrigin(angle: Double) {
        let offset = motion.offset(angle: angle, speed: 900, at: 0)

        #expect(abs(offset.x) < 0.000_001)
        #expect(abs(offset.y) < 0.000_001)
    }

    @Test func negativeTimeStaysAtTheOrigin() {
        let offset = motion.offset(angle: 0.5, speed: 900, at: -2)

        #expect(offset == .zero)
    }

    @Test func withNoSpeedItFallsStraightDown() {
        let early = motion.offset(angle: 0, speed: 0, at: 0.5)
        let late = motion.offset(angle: 0, speed: 0, at: 1)

        #expect(early.x == 0)
        #expect(early.y > 0)
        #expect(late.y > early.y)
    }

    @Test func thrownUpItRisesThenFallsPastTheOrigin() {
        let rising = motion.offset(angle: 0, speed: 1000, at: 0.2)
        let higher = motion.offset(angle: 0, speed: 1000, at: 0.5)
        let fallen = motion.offset(angle: 0, speed: 1000, at: 4)

        #expect(rising.y < 0)
        #expect(higher.y < rising.y)
        #expect(fallen.y > 0)
    }

    @Test func oppositeAnglesMirrorEachOther() {
        let left = motion.offset(angle: -0.7, speed: 800, at: 1.1)
        let right = motion.offset(angle: 0.7, speed: 800, at: 1.1)

        #expect(abs(left.x + right.x) < 0.000_001)
        #expect(abs(left.y - right.y) < 0.000_001)
    }

    @Test func dragLimitsHowFarItTravelsSideways() {
        let speed = 1200.0
        let offset = motion.offset(angle: .pi / 2, speed: speed, at: 60)

        #expect(offset.x <= speed / motion.drag)
        #expect(offset.x > speed / motion.drag * 0.99)
    }

    @Test func fallSettlesAtTerminalSpeed() {
        let first = motion.offset(angle: 0, speed: 500, at: 20)
        let second = motion.offset(angle: 0, speed: 500, at: 21)

        #expect(abs((second.y - first.y) - motion.gravity / motion.drag) < 0.001)
    }

    @Test func zeroDragDoesNotProduceInvalidPositions() {
        let offset = ConfettiBurstMotion(gravity: 800, drag: 0).offset(angle: 0.3, speed: 700, at: 1)

        #expect(offset.x.isFinite)
        #expect(offset.y.isFinite)
    }
}
