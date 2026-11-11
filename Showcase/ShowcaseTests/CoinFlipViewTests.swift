// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct CoinFlipViewTests {
    @Test func halfTurnsAlternateTheVisibleSide() {
        #expect(CoinFlipViewMath.visibleSide(at: 0) == .heads)
        #expect(CoinFlipViewMath.visibleSide(at: 180) == .tails)
        #expect(CoinFlipViewMath.visibleSide(at: 540) == .tails)
        #expect(CoinFlipViewMath.visibleSide(at: 720) == .heads)
    }

    @Test func targetRestsOnTheLandingSide() {
        #expect(CoinFlipViewMath.targetAngle(from: 0, landing: .heads, turns: 5) == 1800)
        #expect(CoinFlipViewMath.targetAngle(from: 0, landing: .tails, turns: 5) == 1980)
        #expect(CoinFlipViewMath.targetAngle(from: 180, landing: .tails, turns: 5) == 1980)
        #expect(CoinFlipViewMath.targetAngle(from: 180, landing: .heads, turns: 5) == 2160)
    }

    @Test func aFlipAlwaysTurnsAtLeastOnce() {
        #expect(CoinFlipViewMath.targetAngle(from: 0, landing: .heads, turns: 0) == 360)
        #expect(CoinFlipViewMath.targetAngle(from: 0, landing: .heads, turns: -9) == 360)
    }

    @Test func hugeTurnCountsAreCapped() {
        #expect(CoinFlipViewMath.targetAngle(from: 0, landing: .heads, turns: .max) == 36_000)
    }
}
