// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct WeatherEffectsBackgroundTests {
    private typealias Math = WeatherEffectsBackgroundMath

    // MARK: - Wrapping

    @Test func aPositionInsideTheTravelStaysWhereItIs() {
        #expect(Math.wrap(30, over: 100) == 30)
    }

    @Test func aPositionPastTheEndComesBackAtTheStart() {
        #expect(Math.wrap(250, over: 100) == 50)
    }

    @Test func aNegativePositionComesBackAtTheEnd() {
        #expect(Math.wrap(-30, over: 100) == 70)
    }

    @Test func noTravelKeepsEverythingAtTheStart() {
        #expect(Math.wrap(42, over: 0) == 0)
    }

    @Test func aPositionJustBeforeTheStartStaysInsideTheTravel() {
        let wrapped = Math.wrap(-1e-17, over: 6)

        #expect(wrapped >= 0 && wrapped < 6)
    }

    @Test func positionsAtTheScaleOfTheClockStillWrapSmoothly() {
        let now = 815_000_000.0 * 700
        let travel = 932.0

        let first = Math.wrap(now, over: travel)
        let next = Math.wrap(now + 7, over: travel)

        #expect(abs(Math.wrap(next - first, over: travel) - 7) < 0.01)
    }

    // MARK: - Lightning

    @Test func mostOfTheCycleHasNoFlash() {
        let samples = stride(from: 0.0, to: Math.lightningCycle, by: 0.01).map { Math.flash(at: $0) }
        let dark = samples.filter { $0 == 0 }

        #expect(Double(dark.count) / Double(samples.count) > 0.9)
    }

    @Test func eachCycleFlashesAtMostTwice() {
        #expect(flashes(from: 0, to: Math.lightningCycle) <= 2)
        #expect(flashes(from: 0, to: Math.lightningCycle) >= 1)
    }

    @Test func noSecondHasMoreThanThreeFlashes() {
        for start in stride(from: 0.0, to: Math.lightningCycle * 2, by: 0.05) {
            #expect(flashes(from: start, to: start + 1) <= 3)
        }
    }

    @Test func aFlashStaysBetweenZeroAndOne() {
        for time in stride(from: -10.0, to: 30, by: 0.003) {
            let flash = Math.flash(at: time)
            #expect(flash >= 0 && flash <= 1)
        }
    }

    @Test func theMomentReduceMotionHoldsIsDark() {
        #expect(Math.flash(at: 0) == 0)
    }

    @Test func theFlashRepeatsEveryCycle() {
        for time in stride(from: 0.0, to: Math.lightningCycle, by: 0.137) {
            #expect(abs(Math.flash(at: time) - Math.flash(at: time + Math.lightningCycle * 3)) < 0.000_1)
        }
    }

    /// Counts how often the flash rises from dark above half its brightness.
    private func flashes(from start: Double, to end: Double) -> Int {
        var count = 0
        var wasLit = Math.flash(at: start) > 0.5
        for time in stride(from: start, to: end, by: 0.002) {
            let isLit = Math.flash(at: time) > 0.5
            if isLit && !wasLit { count += 1 }
            wasLit = isLit
        }
        return count
    }
}
