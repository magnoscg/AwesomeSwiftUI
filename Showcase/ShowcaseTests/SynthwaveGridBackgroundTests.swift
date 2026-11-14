// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct SynthwaveGridBackgroundTests {
    @Test func linesGrowFromTheHorizonAndStayOnTheGround() {
        let lines = SynthwaveGridBackgroundMath.horizontalLines(phase: 0.3, count: 12)

        #expect(zip(lines, lines.dropFirst()).allSatisfy { $0 < $1 })
        #expect(lines.allSatisfy { (0..<1).contains($0) })
    }

    @Test func aFullCycleLandsEachLineOnTheNextOne() {
        let start = SynthwaveGridBackgroundMath.horizontalLines(phase: 0, count: 10)
        let almostDone = SynthwaveGridBackgroundMath.horizontalLines(phase: 0.999_999, count: 10)

        #expect(zip(almostDone, start.dropFirst()).allSatisfy { abs($0 - $1) < 0.001 })
    }

    @Test(arguments: [1.25, -0.75, 7.25])
    func thePhaseWraps(phase: Double) {
        let expected = SynthwaveGridBackgroundMath.horizontalLines(phase: 0.25, count: 6)
        let lines = SynthwaveGridBackgroundMath.horizontalLines(phase: phase, count: 6)

        #expect(zip(lines, expected).allSatisfy { abs($0 - $1) < 0.000_001 })
    }

    @Test(arguments: [(0.5, 0), (0.5, -3), (Double.nan, 4), (Double.infinity, 4)] as [(Double, Int)])
    func invalidInputDrawsNoLines(phase: Double, count: Int) {
        #expect(SynthwaveGridBackgroundMath.horizontalLines(phase: phase, count: count).isEmpty)
    }

    @Test func aHugeCountIsCapped() {
        #expect(SynthwaveGridBackgroundMath.horizontalLines(phase: 0, count: Int.max).count == 128)
    }
}
