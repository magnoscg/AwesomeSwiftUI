// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import CoreGraphics
import Testing
@testable import Showcase

struct CompletionSwipeRowTests {
    @Test func aLongSwipeCompletes() {
        #expect(CompletionSwipeRowMath.shouldComplete(translation: CGSize(width: 150, height: 0), width: 360))
    }

    @Test func aShortSwipeDoesNotComplete() {
        #expect(!CompletionSwipeRowMath.shouldComplete(translation: CGSize(width: 80, height: 0), width: 360))
    }

    @Test func aNarrowRowNeedsLessDistance() {
        #expect(CompletionSwipeRowMath.shouldComplete(translation: CGSize(width: 45, height: 0), width: 100))
    }

    @Test func aWideRowIsCappedAtTheMaximumThreshold() {
        let width: CGFloat = 1_000

        #expect(CompletionSwipeRowMath.shouldComplete(translation: CGSize(width: CompletionSwipeRowMath.maximumThreshold, height: 0), width: width))
    }

    @Test func aSwipeToTheLeftDoesNotComplete() {
        #expect(!CompletionSwipeRowMath.shouldComplete(translation: CGSize(width: -300, height: 0), width: 360))
    }

    @Test func aMostlyVerticalDragDoesNotComplete() {
        #expect(!CompletionSwipeRowMath.shouldComplete(translation: CGSize(width: 160, height: 200), width: 360))
    }

    @Test(arguments: [CGFloat(0), -40])
    func aRowWithNoWidthNeverCompletes(width: CGFloat) {
        #expect(!CompletionSwipeRowMath.shouldComplete(translation: CGSize(width: 500, height: 0), width: width))
    }
}
