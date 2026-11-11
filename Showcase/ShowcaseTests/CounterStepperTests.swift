// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct CounterStepperTests {
    @Test func stepInsideTheRangeAddsTheStep() {
        #expect(CounterStepperValue.stepped(3, by: 2, in: 0...10) == 5)
        #expect(CounterStepperValue.stepped(3, by: -2, in: 0...10) == 1)
    }

    @Test func stepPastABoundStopsAtTheBound() {
        #expect(CounterStepperValue.stepped(9, by: 5, in: 0...10) == 10)
        #expect(CounterStepperValue.stepped(1, by: -5, in: 0...10) == 0)
    }

    @Test func valueOutsideTheRangeIsPulledBackIn() {
        #expect(CounterStepperValue.stepped(50, by: 1, in: 0...10) == 10)
        #expect(CounterStepperValue.stepped(-50, by: -1, in: 0...10) == 0)
    }

    @Test func overflowClampsInsteadOfTrapping() {
        #expect(CounterStepperValue.stepped(.max, by: 1, in: 0...Int.max) == .max)
        #expect(CounterStepperValue.stepped(.min, by: -1, in: Int.min...0) == .min)
    }

    @Test func cannotStepPastEitherBound() {
        #expect(!CounterStepperValue.canStep(10, by: 1, in: 0...10))
        #expect(!CounterStepperValue.canStep(0, by: -1, in: 0...10))
    }

    @Test func canStepAwayFromABound() {
        #expect(CounterStepperValue.canStep(10, by: -1, in: 0...10))
        #expect(CounterStepperValue.canStep(0, by: 1, in: 0...10))
    }
}
