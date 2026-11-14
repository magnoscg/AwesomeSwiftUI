// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI
import Testing
@testable import Showcase

struct ParallaxPushTransitionTests {
    @Test func aRestingPageIsNotShifted() {
        #expect(ParallaxPushTransitionMath.shift(phase: .identity, isForward: true, parallax: 0.3) == 0)
    }

    @Test func pushingBringsThePageInFromTheTrailingEdge() {
        #expect(ParallaxPushTransitionMath.shift(phase: .willAppear, isForward: true, parallax: 0.3) == 1)
    }

    @Test func pushingMovesTheOldPageAwayMoreSlowly() {
        #expect(ParallaxPushTransitionMath.shift(phase: .didDisappear, isForward: true, parallax: 0.3) == -0.3)
    }

    @Test func poppingMirrorsPushing() {
        #expect(ParallaxPushTransitionMath.shift(phase: .willAppear, isForward: false, parallax: 0.3) == -0.3)
        #expect(ParallaxPushTransitionMath.shift(phase: .didDisappear, isForward: false, parallax: 0.3) == 1)
    }
}
