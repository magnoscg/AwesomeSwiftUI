// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Testing
@testable import Showcase

struct BorderBeamModifierTests {
    @Test func headWrapsAroundTheBorder() {
        #expect(BorderBeamModifierMath.head(time: 7, duration: 2) == 0.5)
    }

    @Test func invalidTimingStaysAtTheStart() {
        #expect(BorderBeamModifierMath.head(time: 7, duration: 0) == 0)
        #expect(BorderBeamModifierMath.head(time: 7, duration: -1) == 0)
        #expect(BorderBeamModifierMath.head(time: .infinity, duration: 2) == 0)
    }

    @Test func aRangeInsideTheBorderIsOnePiece() {
        #expect(BorderBeamModifierMath.trims(from: 0.25, to: 0.5) == [0.25...0.5])
    }

    @Test func aRangeAcrossTheSeamIsTwoPieces() {
        #expect(BorderBeamModifierMath.trims(from: 0.75, to: 1.25) == [0.75...1, 0...0.25])
    }

    @Test func negativePositionsWrap() {
        #expect(BorderBeamModifierMath.trims(from: -0.25, to: -0.125) == [0.75...0.875])
    }

    @Test func aRangeEndingOnTheSeamHasNoEmptyPiece() {
        #expect(BorderBeamModifierMath.trims(from: 0.75, to: 1) == [0.75...1])
    }

    @Test func anEmptyRangeDrawsNothing() {
        #expect(BorderBeamModifierMath.trims(from: 0.5, to: 0.5).isEmpty)
    }
}
