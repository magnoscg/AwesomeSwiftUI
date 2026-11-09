// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import CoreGraphics
import Testing
@testable import Showcase

struct FloatingReactionsEmitterTests {
    @Test func aReactionStartsAtItsOrigin() {
        let offset = FloatingReactionsEmitterMath.offset(progress: 0, rise: 300, drift: 40, swayPhase: 1)

        #expect(offset == .zero)
    }

    @Test func aReactionEndsAtTheFullRise() {
        let offset = FloatingReactionsEmitterMath.offset(progress: 1, rise: 300, drift: 40, swayPhase: 0)

        #expect(offset.height == -300)
    }

    @Test func progressPastTheEndStaysAtTheEnd() {
        let end = FloatingReactionsEmitterMath.offset(progress: 1, rise: 300, drift: 40, swayPhase: 0)
        let past = FloatingReactionsEmitterMath.offset(progress: 8, rise: 300, drift: 40, swayPhase: 0)

        #expect(past == end)
    }

    @Test func opacityHoldsThenFades() {
        #expect(FloatingReactionsEmitterMath.opacity(progress: 0.3) == 1)
        #expect(abs(FloatingReactionsEmitterMath.opacity(progress: 0.8) - 0.5) < 0.001)
        #expect(FloatingReactionsEmitterMath.opacity(progress: 3) == 0)
    }

    @Test func scalePopsInAndHolds() {
        #expect(FloatingReactionsEmitterMath.scale(progress: 0) == 0.4)
        #expect(FloatingReactionsEmitterMath.scale(progress: 0.5) == 1)
    }
}
