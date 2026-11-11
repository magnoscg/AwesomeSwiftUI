// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct VerticalTimelineTests {
    @Test func stepsAreDoneCurrentOrUpcoming() {
        #expect(VerticalTimelineStatus.of(index: 0, currentIndex: 1) == .done)
        #expect(VerticalTimelineStatus.of(index: 1, currentIndex: 1) == .current)
        #expect(VerticalTimelineStatus.of(index: 2, currentIndex: 1) == .upcoming)
    }

    @Test func anIndexPastTheEndMeansEverythingIsDone() {
        #expect(VerticalTimelineStatus.of(index: 4, currentIndex: Int.max) == .done)
    }

    @Test func aNegativeIndexMeansNothingHasStarted() {
        #expect(VerticalTimelineStatus.of(index: 0, currentIndex: -1) == .upcoming)
    }
}
