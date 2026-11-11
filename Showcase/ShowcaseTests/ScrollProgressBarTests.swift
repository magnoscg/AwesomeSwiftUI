// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import CoreGraphics
import Testing
@testable import Showcase

struct ScrollProgressBarTests {
    private func progress(offsetY: CGFloat, contentHeight: CGFloat = 1_600, containerHeight: CGFloat = 800) -> CGFloat {
        ScrollProgressBarMath.progress(offsetY: offsetY, topInset: 50, bottomInset: 30, contentHeight: contentHeight, containerHeight: containerHeight)
    }

    @Test func startsAtZeroUnderASafeArea() {
        #expect(progress(offsetY: -50) == 0)
    }

    @Test func reachesOneAtTheBottom() {
        #expect(progress(offsetY: 830) == 1)
    }

    @Test func isHalfwayInTheMiddle() {
        #expect(progress(offsetY: 390) == 0.5)
    }

    @Test(arguments: [CGFloat(-500), 5_000])
    func bounceStaysInRange(offsetY: CGFloat) {
        #expect((0...1).contains(progress(offsetY: offsetY)))
    }

    @Test func contentShorterThanTheScreenStaysAtZero() {
        #expect(progress(offsetY: 0, contentHeight: 100) == 0)
    }
}
