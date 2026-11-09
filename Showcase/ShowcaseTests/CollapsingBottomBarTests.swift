// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import CoreGraphics
import Testing
@testable import Showcase

struct CollapsingBottomBarTests {
    private func state(after offsets: [CGFloat], threshold: CGFloat = 24) -> CollapsingBottomBarState {
        var state = CollapsingBottomBarState()
        for offset in offsets {
            state.update(offset: offset, threshold: threshold)
        }
        return state
    }

    @Test func startsExpanded() {
        #expect(!CollapsingBottomBarState().isCollapsed)
    }

    @Test func staysExpandedForASmallScroll() {
        #expect(!state(after: [10, 20]).isCollapsed)
    }

    @Test func collapsesOnceScrolledPastTheThreshold() {
        #expect(state(after: [10, 20, 30]).isCollapsed)
    }

    @Test func slowScrollingStillAddsUp() {
        #expect(state(after: Array(stride(from: 1, through: 40, by: 1))).isCollapsed)
    }

    @Test func aSmallBounceBackDoesNotExpand() {
        #expect(state(after: [100, 90]).isCollapsed)
    }

    @Test func expandsAfterScrollingBackPastTheThreshold() {
        #expect(!state(after: [100, 200, 170]).isCollapsed)
    }

    @Test func reachingTheTopAlwaysExpands() {
        #expect(!state(after: [100, 90, 0]).isCollapsed)
    }

    @Test func aNegativeThresholdIsTreatedAsZero() {
        #expect(state(after: [1], threshold: -50).isCollapsed)
    }

    @Test(arguments: [(CGFloat(-200), CGFloat(0)), (-50, 0), (150, 200), (5_000, 830)])
    func offsetIgnoresTheRubberBand(offsetY: CGFloat, expected: CGFloat) {
        let clamped = CollapsingBottomBarState.clampedOffset(offsetY: offsetY, topInset: 50, bottomInset: 30, contentHeight: 1_600, containerHeight: 850)

        #expect(clamped == expected)
    }

    @Test func shortContentCannotCollapse() {
        let clamped = CollapsingBottomBarState.clampedOffset(offsetY: 40, topInset: 0, bottomInset: 0, contentHeight: 100, containerHeight: 800)

        #expect(clamped == 0)
    }
}
