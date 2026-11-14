// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

@Suite struct DoubleTapSeekOverlayTests {
    @Test func theLeftHalfSeeksBackward() {
        #expect(DoubleTapSeekOverlayTally.side(forX: 10, width: 100) == .backward)
    }

    @Test func theRightHalfSeeksForward() {
        #expect(DoubleTapSeekOverlayTally.side(forX: 90, width: 100) == .forward)
    }

    @Test func zeroWidthDoesNotCrash() {
        #expect(DoubleTapSeekOverlayTally.side(forX: 0, width: 0) == .forward)
    }

    @Test func repeatedTapsOnOneSideAddUp() {
        var tally = DoubleTapSeekOverlayTally()

        tally.record(.forward, interval: 10)
        tally.record(.forward, interval: 10)

        #expect(tally.side == .forward)
        #expect(tally.seconds == 20)
    }

    @Test func changingSideStartsOver() {
        var tally = DoubleTapSeekOverlayTally()

        tally.record(.forward, interval: 10)
        tally.record(.backward, interval: 10)

        #expect(tally.side == .backward)
        #expect(tally.seconds == 10)
    }

    @Test func resetClearsTheTally() {
        var tally = DoubleTapSeekOverlayTally()
        tally.record(.forward, interval: 10)

        tally.reset()

        #expect(tally == DoubleTapSeekOverlayTally())
    }
}
