// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Testing
@testable import Showcase

struct TapbackReactionBubbleTests {
    @Test func choosingAReactionSetsIt() {
        #expect(TapbackReactionBubbleLogic.toggled(nil, choosing: "👍") == "👍")
    }

    @Test func choosingAnotherReactionReplacesIt() {
        #expect(TapbackReactionBubbleLogic.toggled("❤️", choosing: "😂") == "😂")
    }

    @Test func choosingTheSameReactionTakesItAway() {
        #expect(TapbackReactionBubbleLogic.toggled("❤️", choosing: "❤️") == nil)
    }

    @Test func reactionsPopInOneAfterAnother() {
        #expect(TapbackReactionBubbleLogic.delay(for: 0) == 0)
        #expect(TapbackReactionBubbleLogic.delay(for: 1) == 0.03)
        #expect(TapbackReactionBubbleLogic.delay(for: 3) > TapbackReactionBubbleLogic.delay(for: 2))
    }

    @Test func aLongBarDoesNotKeepTheLastOnesWaiting() {
        #expect(TapbackReactionBubbleLogic.delay(for: 6) == 0.18)
        #expect(TapbackReactionBubbleLogic.delay(for: 30) == 0.18)
    }

    @Test func aNegativeIndexDoesNotWait() {
        #expect(TapbackReactionBubbleLogic.delay(for: -2) == 0)
    }
}
