// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Foundation
import Testing
@testable import Showcase

struct DragToDismissScreenTests {
    @Test func progressFollowsTheDragAndStopsAtOne() {
        #expect(DragToDismissScreenMath.progress(offset: 70, threshold: 140) == 0.5)
        #expect(DragToDismissScreenMath.progress(offset: 900, threshold: 140) == 1)
    }

    @Test func draggingUpHasNoProgress() {
        #expect(DragToDismissScreenMath.progress(offset: -50, threshold: 140) == 0)
    }

    @Test func aZeroThresholdDoesNotDivideByZero() {
        #expect(DragToDismissScreenMath.progress(offset: 0, threshold: 0) == 0)
        #expect(DragToDismissScreenMath.progress(offset: 10, threshold: 0) == 1)
    }

    @Test func aLongDragDismisses() {
        #expect(DragToDismissScreenMath.shouldDismiss(translation: 150, predicted: 150, threshold: 140))
    }

    @Test func aShortSlowDragSpringsBack() {
        #expect(!DragToDismissScreenMath.shouldDismiss(translation: 60, predicted: 90, threshold: 140))
    }

    @Test func aShortFlickDismisses() {
        #expect(DragToDismissScreenMath.shouldDismiss(translation: 60, predicted: 400, threshold: 140))
    }

    @Test func aFlickUpDoesNotDismiss() {
        #expect(!DragToDismissScreenMath.shouldDismiss(translation: 0, predicted: 400, threshold: 140))
    }
}
