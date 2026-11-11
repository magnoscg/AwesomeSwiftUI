// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Foundation
import Testing
@testable import Showcase

struct RichTextEditorTests {
    @Test func wordsAreCountedWhateverSeparatesThem() {
        #expect(RichTextEditorLogic.wordCount(of: AttributedString("Book the night train")) == 4)
        #expect(RichTextEditorLogic.wordCount(of: AttributedString("One\ntwo   three\t four ")) == 4)
    }

    @Test func anEmptyTextHasNoWords() {
        #expect(RichTextEditorLogic.wordCount(of: AttributedString("")) == 0)
        #expect(RichTextEditorLogic.wordCount(of: AttributedString("  \n ")) == 0)
    }

    @Test func formattingDoesNotChangeTheCount() {
        var text = AttributedString("Seats sell ")
        var bold = AttributedString("out fast")
        bold.inlinePresentationIntent = .stronglyEmphasized
        text.append(bold)

        #expect(RichTextEditorLogic.wordCount(of: text) == 4)
    }

    @Test func choosingAFormatSetsIt() {
        #expect(RichTextEditorLogic.toggled(nil, choosing: "yellow") == "yellow")
        #expect(RichTextEditorLogic.toggled("green", choosing: "yellow") == "yellow")
    }

    @Test func choosingTheSameFormatTakesItAway() {
        #expect(RichTextEditorLogic.toggled("yellow", choosing: "yellow") == nil)
    }
}
