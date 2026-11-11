// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct BreathingGuideCircleTests {
    private func state(at elapsed: Double) -> BreathingGuideCircleState {
        BreathingGuideCircleMath.state(at: elapsed, inhale: 2, hold: 1, exhale: 2)
    }

    @Test func expandsWhileBreathingIn() {
        let result = state(at: 1)

        #expect(result.phase == .inhale)
        #expect(result.secondsLeft == 1)
        #expect(abs(result.expansion - 0.5) < 0.000_001)
    }

    @Test func staysFullWhileHolding() {
        let result = state(at: 2.5)

        #expect(result.phase == .hold)
        #expect(result.expansion == 1)
    }

    @Test func contractsWhileBreathingOut() {
        let result = state(at: 4)

        #expect(result.phase == .exhale)
        #expect(abs(result.expansion - 0.5) < 0.000_001)
    }

    @Test func theCycleRepeats() {
        #expect(state(at: 5.5) == state(at: 0.5))
    }

    @Test func negativeTimeWrapsIntoTheCycle() {
        #expect(state(at: -1).phase == .exhale)
    }

    @Test func aZeroHoldIsSkipped() {
        let result = BreathingGuideCircleMath.state(at: 2, inhale: 2, hold: 0, exhale: 2)

        #expect(result.phase == .exhale)
    }

    @Test(arguments: [
        (0.0, 0.0, 0.0),
        (-1.0, -5.0, -2.0),
        (Double.nan, Double.nan, Double.nan),
        (Double.infinity, Double.infinity, Double.infinity),
    ] as [(Double, Double, Double)])
    func invalidDurationsRestAtTheStart(inhale: Double, hold: Double, exhale: Double) {
        let result = BreathingGuideCircleMath.state(at: 3, inhale: inhale, hold: hold, exhale: exhale)

        #expect(result == BreathingGuideCircleState(phase: .inhale, secondsLeft: 0, expansion: 0))
    }

    @Test func invalidTimeRestsAtTheStart() {
        #expect(state(at: .nan).expansion == 0)
    }
}
