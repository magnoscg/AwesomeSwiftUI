// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Testing
@testable import Showcase

struct HideOnScrollBarTests {
    private func tracker(scrollingThrough offsets: [Double], maxOffset: Double = 1_000) -> HideOnScrollBarTracker {
        var tracker = HideOnScrollBarTracker()
        for offset in offsets {
            tracker.update(offset: offset, maxOffset: maxOffset)
        }
        return tracker
    }

    @Test func hidesAfterScrollingDownPastTheThreshold() {
        #expect(tracker(scrollingThrough: [10, 30]).isHidden)
    }

    @Test func staysVisibleForASmallMovement() {
        #expect(!tracker(scrollingThrough: [5, 12]).isHidden)
    }

    @Test func returnsAfterScrollingUpPastTheThreshold() {
        #expect(!tracker(scrollingThrough: [100, 200, 180]).isHidden)
    }

    @Test func aSmallMoveUpDoesNotBringItBack() {
        #expect(tracker(scrollingThrough: [100, 200, 195]).isHidden)
    }

    @Test func alwaysShowsAtTheTop() {
        #expect(!tracker(scrollingThrough: [100, 200, 0]).isHidden)
    }

    @Test func theBounceAtTheBottomDoesNotBringItBack() {
        #expect(tracker(scrollingThrough: [100, 500, 540, 510], maxOffset: 500).isHidden)
    }

    @Test func contentThatDoesNotScrollKeepsTheBar() {
        #expect(!tracker(scrollingThrough: [40, 90], maxOffset: 0).isHidden)
    }
}
