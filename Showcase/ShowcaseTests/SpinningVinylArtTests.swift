// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Foundation
import Testing
@testable import Showcase

@Suite struct SpinningVinylArtTests {
    private let start = Date(timeIntervalSinceReferenceDate: 1_000)

    @Test func staysStillBeforeAnySpeedIsSet() {
        let spin = SpinningVinylArtSpin()

        #expect(spin.angle(at: start) == 0)
    }

    @Test func reachesFullSpeedAfterTheRamp() {
        var spin = SpinningVinylArtSpin(ramp: 1)
        spin.setSpeed(100, at: start)

        #expect(spin.speed(at: start.addingTimeInterval(0.5)) == 50)
        #expect(spin.speed(at: start.addingTimeInterval(1)) == 100)
    }

    @Test func coversTheRampDistanceThenConstantSpeed() {
        var spin = SpinningVinylArtSpin(ramp: 1)
        spin.setSpeed(100, at: start)

        #expect(spin.angle(at: start.addingTimeInterval(1)) == 50)
        #expect(spin.angle(at: start.addingTimeInterval(2)) == 150)
    }

    @Test func easesToAStopAndHoldsTheAngle() {
        var spin = SpinningVinylArtSpin(ramp: 1)
        spin.setSpeed(100, at: start)
        let stopTime = start.addingTimeInterval(2)
        spin.setSpeed(0, at: stopTime)

        let finalAngle = spin.angle(at: stopTime.addingTimeInterval(1))

        #expect(finalAngle == 200)
        #expect(spin.angle(at: stopTime.addingTimeInterval(10)) == finalAngle)
    }

    @Test func aChangeMidRampDoesNotJump() {
        var spin = SpinningVinylArtSpin(ramp: 1)
        spin.setSpeed(100, at: start)
        let changeTime = start.addingTimeInterval(0.5)
        let angleBefore = spin.angle(at: changeTime)
        let speedBefore = spin.speed(at: changeTime)

        spin.setSpeed(0, at: changeTime)

        #expect(spin.angle(at: changeTime) == angleBefore)
        #expect(spin.speed(at: changeTime) == speedBefore)
    }

    @Test func aZeroRampAppliesTheSpeedImmediately() {
        var spin = SpinningVinylArtSpin(ramp: 0)
        spin.setSpeed(90, at: start)

        #expect(spin.speed(at: start) == 90)
        #expect(spin.angle(at: start.addingTimeInterval(2)) == 180)
    }

    @Test func aDateInThePastDoesNotRewind() {
        var spin = SpinningVinylArtSpin(ramp: 1)
        spin.setSpeed(100, at: start)

        #expect(spin.angle(at: start.addingTimeInterval(-5)) == 0)
    }
}
