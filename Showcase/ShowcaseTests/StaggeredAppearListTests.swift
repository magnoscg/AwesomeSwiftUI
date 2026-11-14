// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct StaggeredAppearListTests {
    @Test func firstRowDoesNotWait() {
        #expect(StaggeredAppearListTiming.delay(forIndex: 0) == 0)
    }

    @Test func delayGrowsByOneStepPerRow() {
        let second = StaggeredAppearListTiming.delay(forIndex: 1, step: 0.1, maximum: 10)
        let fourth = StaggeredAppearListTiming.delay(forIndex: 3, step: 0.1, maximum: 10)

        #expect(second == 0.1)
        #expect(fourth == 3 * second)
    }

    @Test func delayNeverDecreasesAlongTheList() {
        let delays = (0..<100).map { StaggeredAppearListTiming.delay(forIndex: $0) }

        #expect(zip(delays, delays.dropFirst()).allSatisfy { $0 <= $1 })
    }

    @Test func longListsStopAtTheMaximum() {
        let delay = StaggeredAppearListTiming.delay(forIndex: 1_000, step: 0.1, maximum: 0.5)

        #expect(delay == 0.5)
    }

    @Test func negativeIndexDoesNotWait() {
        #expect(StaggeredAppearListTiming.delay(forIndex: -3) == 0)
    }

    @Test func reduceMotionRemovesTheDelay() {
        #expect(StaggeredAppearListTiming.delay(forIndex: 9, reduceMotion: true) == 0)
    }
}
