// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct SlotMachineReelsTests {
    private typealias Math = SlotMachineReelsMath

    @Test func theIndexWrapsAroundTheReel() {
        #expect(Math.index(at: 0, count: 6) == 0)
        #expect(Math.index(at: 13, count: 6) == 1)
        #expect(Math.index(at: -1, count: 6) == 5)
    }

    @Test(arguments: 0..<6)
    func aReelStopsOnItsTarget(target: Int) {
        let stop = Math.stop(from: 14, on: target, count: 6, turns: 3)

        #expect(Math.index(at: stop, count: 6) == target)
    }

    @Test func aReelAlwaysTurnsForward() {
        let stop = Math.stop(from: 14, on: 2, count: 6, turns: 3)

        #expect(stop == 14 + 18)
        #expect(Math.stop(from: 14, on: 1, count: 6, turns: 0) == 19)
    }

    @Test func aWinIsEveryReelOnTheSameSymbol() {
        #expect(Math.isWin([4, 4, 4]))
        #expect(!Math.isWin([4, 4, 2]))
        #expect(!Math.isWin([4]))
        #expect(!Math.isWin([]))
    }

    @Test func anEmptyReelDoesNotCrash() {
        #expect(Math.index(at: 5, count: 0) == 0)
        #expect(Math.stop(from: 5, on: 2, count: 0, turns: 3) == 5)
    }
}
