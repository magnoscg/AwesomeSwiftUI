// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct SpinWheelRouletteTests {
    @Test(arguments: [1, 2, 3, 8, 13])
    func theTargetLandsOnTheWinner(count: Int) {
        for winner in 0..<count {
            let target = SpinWheelRouletteMath.targetRotation(from: 123.4, winner: winner, count: count, jitter: 0.3)

            #expect(SpinWheelRouletteMath.winner(rotation: target, count: count) == winner)
        }
    }

    @Test func theWheelAlwaysMovesForwardByAtLeastTheFullTurns() {
        let target = SpinWheelRouletteMath.targetRotation(from: 1_000, winner: 2, count: 6, turns: 5)

        #expect(target >= 1_000 + 5 * 360)
        #expect(target < 1_000 + 6 * 360)
    }

    @Test func negativeTurnsDoNotMoveTheWheelBackwards() {
        #expect(SpinWheelRouletteMath.targetRotation(from: 90, winner: 0, count: 4, turns: -3) >= 90)
    }

    @Test func thereIsNoWinnerWithoutSlices() {
        #expect(SpinWheelRouletteMath.winner(rotation: 45, count: 0) == nil)
    }

    @Test func thereIsNoWinnerForAnInvalidRotation() {
        #expect(SpinWheelRouletteMath.winner(rotation: .nan, count: 4) == nil)
    }

    @Test func aSliceBoundaryBelongsToTheNextSlice() {
        #expect(SpinWheelRouletteMath.winner(rotation: -90, count: 4) == 1)
    }
}
