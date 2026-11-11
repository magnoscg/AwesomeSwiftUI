// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct TypingIndicatorBubbleTests {
    private typealias Timing = TypingIndicatorBubbleTiming

    @Test(arguments: 0..<3)
    func everyDotTakesTheSameTime(index: Int) {
        let total = Timing.delay(for: index, stagger: 0.16) + Timing.bounce + Timing.rest(for: index, stagger: 0.16, period: 1.3)

        #expect(abs(total - 1.3) < 0.000_001)
    }

    @Test func eachDotStartsAfterTheOneBefore() {
        #expect(Timing.delay(for: 0, stagger: 0.16) == 0)
        #expect(Timing.delay(for: 2, stagger: 0.16) > Timing.delay(for: 1, stagger: 0.16))
    }

    @Test func aPeriodTooShortGrowsToFitTheLastDot() {
        let period = Timing.period(0.2, dots: 3, stagger: 0.16)

        #expect(abs(period - 0.82) < 0.000_001)
        #expect(Timing.rest(for: 2, stagger: 0.16, period: period) < 0.000_001)
    }

    @Test func badInputsDoNotGoNegative() {
        #expect(Timing.delay(for: -3, stagger: 0.16) == 0)
        #expect(Timing.delay(for: 2, stagger: -1) == 0)
        #expect(Timing.rest(for: 9, stagger: 0.5, period: 1) == 0)
    }
}
