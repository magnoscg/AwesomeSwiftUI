// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import CoreGraphics
import Testing
@testable import Showcase

struct FireworksBurstTests {
    @Test func aRocketClimbsThenBurstsThenFinishes() {
        #expect(FireworksBurstMath.stage(elapsed: 0) == .climbing(0))
        #expect(FireworksBurstMath.stage(elapsed: FireworksBurstMath.climbDuration) == .bursting(0))
        #expect(FireworksBurstMath.stage(elapsed: FireworksBurstMath.lifetime + 1) == .finished)
    }

    @Test func aNegativeElapsedTimeIsAtTheStart() {
        #expect(FireworksBurstMath.stage(elapsed: -3) == .climbing(0))
        #expect(FireworksBurstMath.stage(elapsed: -3, skipsClimb: true) == .bursting(0))
    }

    @Test func withoutAClimbItBurstsImmediately() {
        #expect(FireworksBurstMath.stage(elapsed: 0, skipsClimb: true) == .bursting(0))
    }

    @Test func sparksStartAtTheCenterAndDroop() {
        let start = FireworksBurstMath.sparkOffset(angle: 0, speed: 100, progress: 0)
        let end = FireworksBurstMath.sparkOffset(angle: 0, speed: 100, progress: 1)

        #expect(start == .zero)
        #expect(end.width == 100)
        #expect(end.height == 70)
    }
}
