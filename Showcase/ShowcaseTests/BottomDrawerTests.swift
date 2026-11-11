// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import CoreGraphics
import Testing
@testable import Showcase

struct BottomDrawerTests {
    private let stops: [CGFloat] = [0.2, 0.5, 0.9]

    @Test func aSmallDragStaysOnTheSameStop() {
        #expect(BottomDrawerSnapping.stop(from: 0.5, predictedDrag: -0.05, stops: stops) == 0.5)
    }

    @Test func aDragUpwardsReachesTheNextStop() {
        #expect(BottomDrawerSnapping.stop(from: 0.5, predictedDrag: -0.3, stops: stops) == 0.9)
    }

    @Test func aDragDownwardsReachesTheLowerStop() {
        #expect(BottomDrawerSnapping.stop(from: 0.5, predictedDrag: 0.2, stops: stops) == 0.2)
    }

    @Test func aFlickCanSkipAStop() {
        #expect(BottomDrawerSnapping.stop(from: 0.2, predictedDrag: -0.65, stops: stops) == 0.9)
    }

    @Test func overshootingEndsOnTheOuterStops() {
        #expect(BottomDrawerSnapping.stop(from: 0.9, predictedDrag: -2, stops: stops) == 0.9)
        #expect(BottomDrawerSnapping.stop(from: 0.2, predictedDrag: 2, stops: stops) == 0.2)
    }

    @Test func withoutStopsTheCurrentValueIsKept() {
        #expect(BottomDrawerSnapping.stop(from: 0.4, predictedDrag: -0.2, stops: []) == 0.4)
    }

    @Test func aStepMovesToTheNeighbouringStop() {
        #expect(BottomDrawerSnapping.stop(from: 0.5, step: 1, stops: stops) == 0.9)
        #expect(BottomDrawerSnapping.stop(from: 0.5, step: -1, stops: stops) == 0.2)
    }

    @Test func aStepIsHeldAtTheEnds() {
        #expect(BottomDrawerSnapping.stop(from: 0.9, step: 1, stops: stops) == 0.9)
        #expect(BottomDrawerSnapping.stop(from: 0.2, step: -1, stops: stops) == 0.2)
    }

    @Test(arguments: [1, -1])
    func aStepWithoutStopsKeepsTheCurrentValue(step: Int) {
        #expect(BottomDrawerSnapping.stop(from: 0.4, step: step, stops: []) == 0.4)
    }

    @Test func dragsAreHeldInsideTheStops() {
        #expect(BottomDrawerSnapping.clamped(1.2, stops: stops) == 0.9)
        #expect(BottomDrawerSnapping.clamped(0.1, stops: stops) == 0.2)
        #expect(BottomDrawerSnapping.clamped(0.6, stops: stops) == 0.6)
    }
}
