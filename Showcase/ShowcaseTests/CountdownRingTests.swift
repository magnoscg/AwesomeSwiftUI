// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Foundation
import Testing
@testable import Showcase

struct CountdownRingTests {
    private let english = Locale(identifier: "en_US")
    private let endDate = Date(timeIntervalSinceReferenceDate: 1_000)

    private func remaining(secondsBeforeEnd: TimeInterval, duration: TimeInterval = 10) -> TimeInterval {
        CountdownRingMath.remaining(
            now: endDate.addingTimeInterval(-secondsBeforeEnd),
            endDate: endDate,
            duration: duration
        )
    }

    @Test func remainingIsTheTimeLeftUntilTheEnd() {
        #expect(remaining(secondsBeforeEnd: 4.5) == 4.5)
    }

    @Test func remainingStopsAtZeroAfterTheEnd() {
        #expect(remaining(secondsBeforeEnd: -3) == 0)
    }

    @Test func remainingNeverExceedsTheDuration() {
        #expect(remaining(secondsBeforeEnd: 25) == 10)
    }

    @Test func remainingIsZeroForANegativeDuration() {
        #expect(remaining(secondsBeforeEnd: 5, duration: -1) == 0)
    }

    @Test(arguments: [(10.0, 1.0), (5.0, 0.5), (0.0, 0.0), (20.0, 1.0), (-2.0, 0.0)])
    func fractionFollowsTheRemainingTime(remaining: TimeInterval, expected: Double) {
        #expect(CountdownRingMath.fraction(remaining: remaining, duration: 10) == expected)
    }

    @Test func fractionIsZeroWithoutADuration() {
        #expect(CountdownRingMath.fraction(remaining: 5, duration: 0) == 0)
    }

    @Test(arguments: [(10.0, 10), (9.2, 10), (9.0, 9), (0.01, 1), (0.0, 0), (-1.0, 0)])
    func wholeSecondsRoundUp(remaining: TimeInterval, expected: Int) {
        #expect(CountdownRingMath.wholeSeconds(remaining: remaining) == expected)
    }

    @Test(arguments: [(0, "0"), (45, "45"), (59, "59"), (60, "1:00"), (65, "1:05"), (600, "10:00")])
    func textSwitchesToMinutesAtSixtySeconds(seconds: Int, expected: String) {
        #expect(CountdownRingMath.text(seconds: seconds, locale: english) == expected)
    }
}
