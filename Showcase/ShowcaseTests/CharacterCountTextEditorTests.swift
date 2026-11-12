// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct CharacterCountTextEditorTests {
    @Test func belowTheWarningIsNormal() {
        #expect(CharacterCountTextEditorLevel(count: 0, limit: 280) == .normal)
        #expect(CharacterCountTextEditorLevel(count: 251, limit: 280) == .normal)
    }

    @Test func fromNinetyPercentUpToTheLimitIsAWarning() {
        #expect(CharacterCountTextEditorLevel(count: 252, limit: 280) == .warning)
        #expect(CharacterCountTextEditorLevel(count: 280, limit: 280) == .warning)
    }

    @Test func onlyPastTheLimitIsOver() {
        #expect(CharacterCountTextEditorLevel(count: 281, limit: 280) == .over)
    }

    @Test func theWarningFractionCanChange() {
        #expect(CharacterCountTextEditorLevel(count: 40, limit: 80, warningFraction: 0.5) == .warning)
        #expect(CharacterCountTextEditorLevel(count: 39, limit: 80, warningFraction: 0.5) == .normal)
    }

    @Test func anEmojiCountsAsOneCharacter() {
        #expect(CharacterCountTextEditorLevel.count(of: "👨‍👩‍👧") == 1)
        #expect(CharacterCountTextEditorLevel.count(of: "café") == 4)
    }
}
