// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import CoreGraphics
import Testing
@testable import Showcase

struct StickyStackedCardsTests {
    @Test func aCardBelowItsPinDoesNotMove() {
        #expect(StickyStackedCardsMath.pinOffset(cardTop: 300, pinY: 12) == 0)
    }

    @Test func aCardPastItsPinIsHeldThere() {
        #expect(StickyStackedCardsMath.pinOffset(cardTop: -188, pinY: 12) == 200)
    }

    @Test func pinsStepDownThenStop() {
        let pins = (0..<6).map { StickyStackedCardsMath.pinY(index: $0, top: 10, peek: 12, maxPeeking: 3) }

        #expect(pins == [10, 22, 34, 46, 46, 46])
    }

    @Test func aNegativePeekCannotPullCardsUp() {
        #expect(StickyStackedCardsMath.pinY(index: 2, top: 10, peek: -12, maxPeeking: 3) == 10)
    }

    @Test func aCardNotYetCoveredKeepsItsSize() {
        #expect(StickyStackedCardsMath.scale(pinOffset: 0, cardHeight: 300, spacing: 20, step: 0.05) == 1)
    }

    @Test func aCardShrinksOneStepPerCardOnTopOfIt() {
        #expect(StickyStackedCardsMath.scale(pinOffset: 320, cardHeight: 300, spacing: 20, step: 0.05) == 0.95)
    }

    @Test func aZeroSizedCardDoesNotDivideByZero() {
        #expect(StickyStackedCardsMath.scale(pinOffset: 100, cardHeight: 0, spacing: 0, step: 0.05) == 1)
    }

    @Test func scaleNeverCollapses() {
        #expect(StickyStackedCardsMath.scale(pinOffset: 1_000_000, cardHeight: 10, spacing: 0, step: 0.9) == 0.6)
    }
}
