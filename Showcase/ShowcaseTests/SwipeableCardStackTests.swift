// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

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

    @Test func positionsCoverTheFlyingCardTheTopAndThreeBehind() {
        #expect(SwipeableCardStackLogic.positions(top: 2, count: 8, loops: false) == [1, 2, 3, 4, 5])
    }

    @Test func positionsStopAtTheEndOfTheDeck() {
        #expect(SwipeableCardStackLogic.positions(top: 4, count: 5, loops: false) == [3, 4])
        #expect(SwipeableCardStackLogic.positions(top: 5, count: 5, loops: false) == [4])
    }

    @Test func aLoopingDeckKeepsGoingPastItsEnd() {
        #expect(SwipeableCardStackLogic.positions(top: 4, count: 5, loops: true) == [3, 4, 5, 6, 7])
    }

    @Test func aDeckThatShrinksBelowTheSwipedCardsHasNoPositions() {
        #expect(SwipeableCardStackLogic.positions(top: 3, count: 1, loops: false).isEmpty)
    }

    @Test func anEmptyDeckHasNoPositions() {
        #expect(SwipeableCardStackLogic.positions(top: 0, count: 0, loops: true).isEmpty)
    }

    @Test(arguments: [0, -50] as [CGFloat])
    func aCardWithoutWidthNeverSwipes(width: CGFloat) {
        #expect(SwipeableCardStackLogic.direction(predictedEnd: 400, width: width) == nil)
    }
}
