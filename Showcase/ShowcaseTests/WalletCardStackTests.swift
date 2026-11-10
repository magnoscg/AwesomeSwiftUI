// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Testing
@testable import Showcase

struct WalletCardStackTests {
    @Test func cardsSitOnePeekApartWhenTheyFit() {
        #expect(WalletCardStackMath.step(count: 4, peek: 64, cardHeight: 200, height: 600) == 64)
    }

    @Test func theStackTightensToFit() {
        #expect(WalletCardStackMath.step(count: 5, peek: 64, cardHeight: 200, height: 400) == 50)
    }

    @Test func aSingleCardNeedsNoStep() {
        #expect(WalletCardStackMath.step(count: 1, peek: 64, cardHeight: 200, height: 600) == 0)
        #expect(WalletCardStackMath.step(count: 0, peek: 64, cardHeight: 200, height: 600) == 0)
    }

    @Test func aStackWithNoRoomCollapses() {
        #expect(WalletCardStackMath.step(count: 3, peek: 64, cardHeight: 200, height: 120) == 0)
        #expect(WalletCardStackMath.step(count: 3, peek: -8, cardHeight: 200, height: 600) == 0)
        #expect(WalletCardStackMath.step(count: 3, peek: .nan, cardHeight: 200, height: 600) == 0)
    }

    @Test func closedCardsGoOneBelowAnother() {
        #expect(WalletCardStackMath.tops(count: 3, selected: nil, step: 64, height: 600, pileHeight: 76) == [0, 64, 128])
    }

    @Test func theOpenCardRisesAndTheOthersPileAtTheBottom() {
        let tops = WalletCardStackMath.tops(count: 4, selected: 1, step: 64, height: 600, pileHeight: 76, pileStep: 14)

        #expect(tops == [524, 0, 538, 552])
    }

    @Test func aCrowdedPileStaysInsideItsRoom() {
        let tops = WalletCardStackMath.tops(count: 11, selected: 0, step: 20, height: 600, pileHeight: 70, pileStep: 14)

        #expect(tops[1] == 530)
        #expect(tops[10] == 593)
    }

    @Test func aSelectionOutOfRangeLeavesTheStackClosed() {
        #expect(WalletCardStackMath.tops(count: 2, selected: 5, step: 64, height: 600, pileHeight: 76) == [0, 64])
        #expect(WalletCardStackMath.tops(count: 2, selected: -1, step: 64, height: 600, pileHeight: 76) == [0, 64])
    }

    @Test func noCardsHaveNoTops() {
        #expect(WalletCardStackMath.tops(count: 0, selected: nil, step: 64, height: 600, pileHeight: 76).isEmpty)
    }

    @Test func aLoneOpenCardStaysAtTheTop() {
        #expect(WalletCardStackMath.tops(count: 1, selected: 0, step: 0, height: 600, pileHeight: 76) == [0])
    }
}
