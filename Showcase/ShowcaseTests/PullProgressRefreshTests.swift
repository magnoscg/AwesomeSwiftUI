// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import CoreGraphics
import Testing
@testable import Showcase

struct PullProgressRefreshTests {
    @Test func restingUnderASafeAreaIsNotAPull() {
        #expect(PullProgressRefreshMath.pullDistance(contentOffsetY: -59, topInset: 59) == 0)
    }

    @Test func overscrollCountsAsAPull() {
        #expect(PullProgressRefreshMath.pullDistance(contentOffsetY: -99, topInset: 59) == 40)
    }

    @Test func scrollingDownIsNotAPull() {
        #expect(PullProgressRefreshMath.pullDistance(contentOffsetY: 300, topInset: 59) == 0)
    }

    @Test(arguments: [(CGFloat(0), CGFloat(0)), (45, 0.5), (90, 1), (500, 1), (-10, 0)])
    func progressIsAClampedFraction(pull: CGFloat, expected: CGFloat) {
        #expect(PullProgressRefreshMath.progress(pull: pull, threshold: 90) == expected)
    }

    @Test(arguments: [CGFloat(0), -20])
    func invalidThresholdDoesNotDivideByZero(threshold: CGFloat) {
        #expect(PullProgressRefreshMath.progress(pull: 0, threshold: threshold) == 0)
        #expect(PullProgressRefreshMath.progress(pull: 10, threshold: threshold) == 1)
    }
}
