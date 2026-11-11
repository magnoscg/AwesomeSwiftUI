// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct RatingStarsTests {
    @Test func keepsARatingInsideTheRange() {
        #expect(RatingStarsValue.clamped(3, maximum: 5) == 3)
    }

    @Test func aTapOnAnotherStarChoosesIt() {
        #expect(RatingStarsValue.tapping(4, rating: 2, maximum: 5) == 4)
    }

    @Test func aTapOnTheChosenStarClearsTheRating() {
        #expect(RatingStarsValue.tapping(3, rating: 3, maximum: 5) == 0)
    }

    @Test func keepsTheBoundaries() {
        #expect(RatingStarsValue.clamped(0, maximum: 5) == 0)
        #expect(RatingStarsValue.clamped(5, maximum: 5) == 5)
    }

    @Test func raisesNegativeRatingsToZero() {
        #expect(RatingStarsValue.clamped(-2, maximum: 5) == 0)
    }

    @Test func lowersRatingsAboveTheMaximum() {
        #expect(RatingStarsValue.clamped(6, maximum: 5) == 5)
    }

    @Test func aNegativeMaximumGivesZero() {
        #expect(RatingStarsValue.clamped(3, maximum: -1) == 0)
    }
}
