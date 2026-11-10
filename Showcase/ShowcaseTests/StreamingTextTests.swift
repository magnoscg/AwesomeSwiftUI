// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Testing
@testable import Showcase

struct StreamingTextTests {
    @Test func aCharacterAheadOfTheFrontIsClear() {
        #expect(StreamingTextMath.opacity(of: 20, visible: 12, fade: 10) == 0)
        #expect(StreamingTextMath.opacity(of: 12, visible: 12, fade: 10) == 0)
    }

    @Test func aCharacterTheFrontHasPassedIsWhole() {
        #expect(StreamingTextMath.opacity(of: 2, visible: 12, fade: 10) == 1)
        #expect(StreamingTextMath.opacity(of: 0, visible: 40, fade: 10) == 1)
    }

    @Test func aCharacterOnTheEdgeIsPartlyThere() {
        #expect(StreamingTextMath.opacity(of: 7, visible: 12, fade: 10) == 0.5)
        #expect(StreamingTextMath.opacity(of: 10, visible: 12, fade: 10) < StreamingTextMath.opacity(of: 8, visible: 12, fade: 10))
    }

    @Test func noFadeMakesAHardEdge() {
        #expect(StreamingTextMath.opacity(of: 11, visible: 12, fade: 0) == 1)
        #expect(StreamingTextMath.opacity(of: 12, visible: 12, fade: 0) == 0)
    }

    @Test func theLastCharacterIsWholeOnceTheFrontIsPastTheEnd() {
        #expect(StreamingTextMath.opacity(of: 99, visible: 100 + 10, fade: 10) == 1)
    }

    @Test func moreTextTakesLonger() {
        #expect(StreamingTextMath.duration(for: 40, charactersPerSecond: 80) == 0.5)
        #expect(StreamingTextMath.duration(for: 80, charactersPerSecond: 80) == 1)
    }

    @Test func aWordIsNotInstantAndABurstDoesNotDrag() {
        #expect(StreamingTextMath.duration(for: 3, charactersPerSecond: 80) == 0.15)
        #expect(StreamingTextMath.duration(for: 900, charactersPerSecond: 80) == 1.5)
    }

    @Test func nothingToShowTakesTheShortestTime() {
        #expect(StreamingTextMath.duration(for: 0, charactersPerSecond: 80) == 0.15)
        #expect(StreamingTextMath.duration(for: -5, charactersPerSecond: 80) == 0.15)
        #expect(StreamingTextMath.duration(for: 40, charactersPerSecond: 0) == 0.15)
    }

    @Test func extendedTextKeepsAllItHad() {
        #expect(StreamingTextMath.sharedPrefix("Hello", "Hello there") == 5)
    }

    @Test func replacedTextKeepsOnlyWhatMatches() {
        #expect(StreamingTextMath.sharedPrefix("Hello there", "Help") == 3)
        #expect(StreamingTextMath.sharedPrefix("Hello", "World") == 0)
        #expect(StreamingTextMath.sharedPrefix("", "World") == 0)
    }

    @Test func anEmojiCountsAsOneCharacter() {
        #expect(StreamingTextMath.sharedPrefix("Hi 👋🏽 you", "Hi 👋🏽 all") == 5)
    }
}
