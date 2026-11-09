// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import CoreGraphics
import Testing
@testable import Showcase

struct SwipeableCardStackTests {
    @Test func shortReleaseStaysInTheDeck() {
        #expect(SwipeableCardStackLogic.direction(predictedEnd: 100, width: 300, threshold: 0.35) == nil)
        #expect(SwipeableCardStackLogic.direction(predictedEnd: -100, width: 300, threshold: 0.35) == nil)
    }

    @Test func reachingTheThresholdSwipes() {
        #expect(SwipeableCardStackLogic.direction(predictedEnd: 105, width: 300, threshold: 0.35) == .right)
        #expect(SwipeableCardStackLogic.direction(predictedEnd: -105, width: 300, threshold: 0.35) == .left)
    }

    @Test func thresholdScalesWithWidth() {
        #expect(SwipeableCardStackLogic.direction(predictedEnd: 120, width: 300) == .right)
        #expect(SwipeableCardStackLogic.direction(predictedEnd: 120, width: 600) == nil)
    }

    @Test(arguments: [0, -50] as [CGFloat])
    func aCardWithoutWidthNeverSwipes(width: CGFloat) {
        #expect(SwipeableCardStackLogic.direction(predictedEnd: 400, width: width) == nil)
    }
}
