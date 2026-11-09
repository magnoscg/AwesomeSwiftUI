// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import CoreGraphics
import Testing
@testable import Showcase

struct LongPressRadialMenuTests {
    private let radius: CGFloat = 100

    private func index(_ x: CGFloat, _ y: CGFloat, count: Int = 4) -> Int? {
        LongPressRadialMenuMath.index(translation: CGSize(width: x, height: y), count: count, radius: radius)
    }

    @Test func theFirstItemIsAtTheTop() {
        let offset = LongPressRadialMenuMath.offset(index: 0, count: 4, radius: radius)

        #expect(abs(offset.width) < 0.001)
        #expect(abs(offset.height + radius) < 0.001)
    }

    @Test func itemsGoClockwise() {
        let offset = LongPressRadialMenuMath.offset(index: 1, count: 4, radius: radius)

        #expect(abs(offset.width - radius) < 0.001)
        #expect(abs(offset.height) < 0.001)
    }

    @Test func aDragPicksTheItemInThatDirection() {
        #expect(index(0, -100) == 0)
        #expect(index(100, 0) == 1)
        #expect(index(0, 100) == 2)
        #expect(index(-100, 0) == 3)
    }

    @Test func aDragJustBeforeTheTopWrapsToTheFirstItem() {
        #expect(index(-5, -100) == 0)
    }

    @Test func nearTheCenterNothingIsPicked() {
        #expect(index(0, 0) == nil)
        #expect(index(20, -20) == nil)
    }

    @Test func aDragFarPastTheRingStillPicks() {
        #expect(index(0, -900) == 0)
    }

    @Test func oneItemIsPickedFromAnyDirection() {
        #expect(index(100, 40, count: 1) == 0)
        #expect(index(-30, 100, count: 1) == 0)
    }

    @Test(arguments: [0, -2])
    func noItemsPickNothing(count: Int) {
        #expect(index(0, -100, count: count) == nil)
        #expect(LongPressRadialMenuMath.angle(index: 1, count: count) == 0)
    }

    @Test(arguments: [CGFloat(0), -50])
    func aZeroRadiusPicksNothing(radius: CGFloat) {
        let result = LongPressRadialMenuMath.index(translation: CGSize(width: 0, height: -100), count: 4, radius: radius)

        #expect(result == nil)
    }
}
