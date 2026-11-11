// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct KaraokeLyricsTextTests {
    @Test func nothingIsSungAtTheStart() {
        #expect(KaraokeLyricsTextMath.fills(widths: [120, 80], progress: 0) == [0, 0])
    }

    @Test func everythingIsSungAtTheEnd() {
        #expect(KaraokeLyricsTextMath.fills(widths: [120, 80], progress: 1) == [1, 1])
    }

    @Test func linesFillInOrder() {
        #expect(KaraokeLyricsTextMath.fills(widths: [100, 100], progress: 0.5) == [1, 0])
        #expect(KaraokeLyricsTextMath.fills(widths: [100, 100], progress: 0.75) == [1, 0.5])
    }

    @Test func aWiderLineTakesLonger() {
        #expect(KaraokeLyricsTextMath.fills(widths: [100, 300], progress: 0.5) == [1, 1.0 / 3])
    }

    @Test func progressOutsideItsRangeIsClamped() {
        #expect(KaraokeLyricsTextMath.fills(widths: [100, 100], progress: -2) == [0, 0])
        #expect(KaraokeLyricsTextMath.fills(widths: [100, 100], progress: 7) == [1, 1])
    }

    @Test func anEmptyLineIsSkipped() {
        #expect(KaraokeLyricsTextMath.fills(widths: [100, 0, 100], progress: 0.75) == [1, 0, 0.5])
    }

    @Test func textWithNoWidthStaysUnsung() {
        #expect(KaraokeLyricsTextMath.fills(widths: [0, 0], progress: 0.8) == [0, 0])
        #expect(KaraokeLyricsTextMath.fills(widths: [], progress: 0.8).isEmpty)
        #expect(KaraokeLyricsTextMath.fills(widths: [100], progress: .nan) == [0])
    }

    @Test func withoutTheSweepALineLightsUpWhole() {
        #expect(KaraokeLyricsTextMath.wholeLines([1, 0.2, 0]) == [1, 1, 0])
    }
}
