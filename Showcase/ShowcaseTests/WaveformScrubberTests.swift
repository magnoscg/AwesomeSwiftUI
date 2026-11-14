// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

@Suite struct WaveformScrubberTests {
    @Test func aTouchMapsToAFraction() {
        #expect(WaveformScrubberMath.progress(forX: 25, width: 100) == 0.25)
    }

    @Test func touchesOutsideAreClamped() {
        #expect(WaveformScrubberMath.progress(forX: -40, width: 100) == 0)
        #expect(WaveformScrubberMath.progress(forX: 900, width: 100) == 1)
    }

    @Test func zeroWidthIsSafe() {
        #expect(WaveformScrubberMath.progress(forX: 50, width: 0) == 0)
    }

    @Test func barsAverageTheirBuckets() {
        let bars = WaveformScrubberMath.bars(from: [0, 1, 1, 1], count: 2)

        #expect(bars == [0.5, 1])
    }

    @Test func moreBarsThanSamplesStillGivesEveryBar() {
        let bars = WaveformScrubberMath.bars(from: [0.2, 0.8], count: 5)

        #expect(bars.count == 5)
    }

    @Test func emptyInputsGiveNoBars() {
        #expect(WaveformScrubberMath.bars(from: [], count: 10).isEmpty)
        #expect(WaveformScrubberMath.bars(from: [1], count: 0).isEmpty)
    }

    @Test func badSamplesAreClamped() {
        let bars = WaveformScrubberMath.bars(from: [.nan, 4, -3], count: 3)

        #expect(bars == [0, 1, 0])
    }

    @Test func barCountHandlesBadSizes() {
        #expect(WaveformScrubberMath.barCount(width: 100, barWidth: 3, spacing: 2) == 20)
        #expect(WaveformScrubberMath.barCount(width: 100, barWidth: 0, spacing: 0) == 0)
        #expect(WaveformScrubberMath.barCount(width: -5, barWidth: 3, spacing: 2) == 0)
    }
}
