// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Testing
@testable import Showcase

struct AnimatedBadgeCountTests {
    @Test(arguments: [0, -1, Int.min])
    func nothingToCountHidesTheBadge(count: Int) {
        #expect(AnimatedBadgeCountFormat.text(count: count, maximum: 99) == nil)
    }

    @Test func aCountWithinTheMaximumShowsItself() {
        #expect(AnimatedBadgeCountFormat.text(count: 99, maximum: 99) == "99")
    }

    @Test(arguments: [100, Int.max])
    func aCountOverTheMaximumIsCapped(count: Int) {
        #expect(AnimatedBadgeCountFormat.text(count: count, maximum: 99) == "99+")
    }

    @Test(arguments: [0, -5])
    func aNonsenseMaximumFallsBackToOne(maximum: Int) {
        #expect(AnimatedBadgeCountFormat.text(count: 3, maximum: maximum) == "1+")
    }
}
