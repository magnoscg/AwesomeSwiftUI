// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct RangeSliderTests {
    private let bounds = 20.0...300.0

    @Test func aValueBecomesAFractionOfTheTrack() {
        #expect(RangeSliderMath.fraction(of: 20, in: bounds) == 0)
        #expect(RangeSliderMath.fraction(of: 160, in: bounds) == 0.5)
        #expect(RangeSliderMath.fraction(of: 300, in: bounds) == 1)
    }

    @Test func aValueOutsideTheBoundsStaysOnTheTrack() {
        #expect(RangeSliderMath.fraction(of: -40, in: bounds) == 0)
        #expect(RangeSliderMath.fraction(of: 900, in: bounds) == 1)
        #expect(RangeSliderMath.fraction(of: .nan, in: bounds) == 0)
        #expect(RangeSliderMath.fraction(of: 5, in: 5...5) == 0)
    }

    @Test func stepsCountFromTheStartOfTheBounds() {
        #expect(RangeSliderMath.snapped(63, in: bounds, step: 5) == 65)
        #expect(RangeSliderMath.snapped(62, in: bounds, step: 5) == 60)
        #expect(RangeSliderMath.snapped(62.4, in: bounds, step: 0) == 62.4)
        #expect(RangeSliderMath.snapped(12, in: 3...33, step: 10) == 13)
    }

    @Test func theLowerEndStaysInsideTheBounds() {
        #expect(RangeSliderMath.lower(-50, upper: 180, in: bounds) == 20)
        #expect(RangeSliderMath.lower(90, upper: 180, in: bounds) == 90)
    }

    @Test func theLowerEndStopsBeforeTheUpperOne() {
        #expect(RangeSliderMath.lower(250, upper: 180, in: bounds) == 180)
        #expect(RangeSliderMath.lower(250, upper: 180, in: bounds, minimumSpan: 20) == 160)
        #expect(RangeSliderMath.lower(170, upper: 180, in: bounds, step: 5, minimumSpan: 20) == 160)
    }

    @Test func theUpperEndStaysInsideTheBounds() {
        #expect(RangeSliderMath.upper(900, lower: 60, in: bounds) == 300)
        #expect(RangeSliderMath.upper(140, lower: 60, in: bounds) == 140)
    }

    @Test func theUpperEndStopsAfterTheLowerOne() {
        #expect(RangeSliderMath.upper(10, lower: 60, in: bounds) == 60)
        #expect(RangeSliderMath.upper(10, lower: 60, in: bounds, minimumSpan: 20) == 80)
        #expect(RangeSliderMath.upper(65, lower: 60, in: bounds, step: 5, minimumSpan: 20) == 80)
    }

    @Test func theEndsNeverCrossEvenWithNoRoomForTheMinimum() {
        #expect(RangeSliderMath.lower(100, upper: 30, in: bounds, minimumSpan: 20) == 20)
        #expect(RangeSliderMath.upper(100, lower: 290, in: bounds, minimumSpan: 20) == 300)
        #expect(RangeSliderMath.lower(.nan, upper: 180, in: bounds) == 20)
        #expect(RangeSliderMath.upper(.nan, lower: 60, in: bounds) == 300)
    }

    @Test func aTouchTakesTheNearestThumb() {
        #expect(RangeSliderMath.thumb(nearest: 0.1, lower: 0.2, upper: 0.8) == .lower)
        #expect(RangeSliderMath.thumb(nearest: 0.7, lower: 0.2, upper: 0.8) == .upper)
        #expect(RangeSliderMath.thumb(nearest: 0.45, lower: 0.2, upper: 0.8) == .lower)
    }

    @Test func thumbsOnTheSameSpotAreTakenByTheSideOfTheTouch() {
        #expect(RangeSliderMath.thumb(nearest: 0.3, lower: 0.5, upper: 0.5) == .lower)
        #expect(RangeSliderMath.thumb(nearest: 0.6, lower: 0.5, upper: 0.5) == .upper)
    }

    @Test func thumbsAtOneEndNeverGetStuck() {
        #expect(RangeSliderMath.thumb(nearest: 1, lower: 1, upper: 1) == .lower)
        #expect(RangeSliderMath.thumb(nearest: 0, lower: 0, upper: 0) == .upper)
    }
}
