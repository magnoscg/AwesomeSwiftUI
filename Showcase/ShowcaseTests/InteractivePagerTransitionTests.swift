// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import CoreGraphics
import Testing
@testable import Showcase

struct InteractivePagerTransitionTests {
    private func target(index: Int = 1, count: Int = 3, translation: CGFloat, predicted: CGFloat = 0, width: CGFloat = 400) -> Int {
        InteractivePagerTransitionMath.targetIndex(index: index, count: count, translation: translation, predicted: predicted, width: width)
    }

    @Test func aFarDragToTheLeftGoesToTheNextPage() {
        #expect(target(translation: -200) == 2)
    }

    @Test func aFarDragToTheRightGoesBack() {
        #expect(target(translation: 200) == 0)
    }

    @Test func aShortDragCancels() {
        #expect(target(translation: -60, predicted: -80) == 1)
    }

    @Test func aFlickCommitsEvenWhenShort() {
        #expect(target(translation: -60, predicted: -300) == 2)
    }

    @Test func cannotGoPastTheLastPage() {
        #expect(target(index: 2, translation: -300) == 2)
    }

    @Test func cannotGoBeforeTheFirstPage() {
        #expect(target(index: 0, translation: 300) == 0)
    }

    @Test func noPagesStaysAtZero() {
        #expect(target(index: 5, count: 0, translation: -300) == 0)
    }

    @Test func aZeroWidthNeverCommits() {
        #expect(target(translation: -300, width: 0) == 1)
    }

    @Test(arguments: [Int.max, Int.min])
    func extremeIndexesAreClamped(index: Int) {
        #expect((0..<3).contains(InteractivePagerTransitionMath.clampedIndex(index, count: 3)))
    }

    @Test func dragsAtTheEndsAreResisted() {
        #expect(InteractivePagerTransitionMath.resisted(translation: 100, index: 0, count: 3) == 30)
        #expect(InteractivePagerTransitionMath.resisted(translation: -100, index: 2, count: 3) == -30)
    }

    @Test func dragsInTheMiddleAreNotResisted() {
        #expect(InteractivePagerTransitionMath.resisted(translation: 100, index: 1, count: 3) == 100)
    }

    @Test func theCenteredPageIsNotOffset() {
        #expect(InteractivePagerTransitionMath.offsetX(relative: 0, width: 400, parallax: true) == 0)
    }

    @Test func thePageBelowMovesSlower() {
        #expect(InteractivePagerTransitionMath.offsetX(relative: -1, width: 400, parallax: true) == -120)
        #expect(InteractivePagerTransitionMath.offsetX(relative: 1, width: 400, parallax: true) == 400)
    }

    @Test func withoutParallaxPagesSlideTogether() {
        #expect(InteractivePagerTransitionMath.offsetX(relative: -1, width: 400, parallax: false) == -400)
        #expect(InteractivePagerTransitionMath.scale(relative: -1, parallax: false) == 1)
    }
}
