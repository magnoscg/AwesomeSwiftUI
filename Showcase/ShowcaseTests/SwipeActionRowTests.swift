// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import CoreGraphics
import Testing
@testable import Showcase

struct SwipeActionRowTests {
    @Test func followsTheFingerWhileOpening() {
        #expect(SwipeActionRowPhysics.offset(resting: 0, translation: -60, revealWidth: 160) == -60)
    }

    @Test func doesNotMoveRightOfClosed() {
        #expect(SwipeActionRowPhysics.offset(resting: 0, translation: 80, revealWidth: 160) == 0)
    }

    @Test func resistsPastFullyOpen() {
        #expect(SwipeActionRowPhysics.offset(resting: -160, translation: -40, revealWidth: 160) == -170)
    }

    @Test func opensPastHalfway() {
        #expect(SwipeActionRowPhysics.settlesOpen(resting: 0, predictedTranslation: -100, revealWidth: 160))
        #expect(!SwipeActionRowPhysics.settlesOpen(resting: 0, predictedTranslation: -60, revealWidth: 160))
    }

    @Test func closesFromOpenWithASwipeRight() {
        #expect(!SwipeActionRowPhysics.settlesOpen(resting: -160, predictedTranslation: 120, revealWidth: 160))
    }

    @Test func aRowWithoutActionsNeverOpens() {
        #expect(!SwipeActionRowPhysics.settlesOpen(resting: 0, predictedTranslation: -500, revealWidth: 0))
    }
}
