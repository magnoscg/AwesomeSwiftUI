// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import CoreGraphics
import Testing
@testable import Showcase

struct TagInputFieldTests {
    private let marker = TagInputFieldLogic.marker

    @Test func aNewTagGoesAtTheEndTrimmed() {
        #expect(TagInputFieldLogic.adding(["  spicy "], to: ["vegan"]) == ["vegan", "spicy"])
    }

    @Test func emptyAndRepeatedTagsAreLeftOut() {
        #expect(TagInputFieldLogic.adding(["", "  ", "Vegan", "quick", "QUICK"], to: ["vegan"]) == ["vegan", "quick"])
    }

    @Test func typingKeepsTheTextUntilASeparator() {
        let result = TagInputFieldLogic.typing("\(marker)spi", after: "\(marker)sp", tags: [])

        #expect(result.tags.isEmpty)
        #expect(result.text == "\(marker)spi")
    }

    @Test func aCommaTurnsTheTextIntoATag() {
        let result = TagInputFieldLogic.typing("spicy,", after: "spicy", tags: [])

        #expect(result.tags == ["spicy"])
        #expect(result.text == marker)
    }

    @Test func pastedTextAddsATagForEachPiece() {
        let result = TagInputFieldLogic.typing("\(marker)red, green,\nblue", after: marker, tags: ["black"])

        #expect(result.tags == ["black", "red", "green"])
        #expect(result.text == "\(marker)blue")
    }

    @Test func aMissingMarkerIsPutBack() {
        #expect(TagInputFieldLogic.typing("a", after: "", tags: []).text == "\(marker)a")
        #expect(TagInputFieldLogic.typing("", after: "", tags: ["vegan"]).text == marker)
        #expect(TagInputFieldLogic.typing("\(marker)a\(marker)", after: marker, tags: []).text == "\(marker)a")
    }

    @Test func textWithItsMarkerIsLeftAsItIs() {
        #expect(TagInputFieldLogic.typing("a\(marker)", after: marker, tags: []).text == "a\(marker)")
        #expect(TagInputFieldLogic.typing("\(marker)ab", after: "\(marker)a", tags: ["vegan"]).text == "\(marker)ab")
    }

    @Test func deleteInAnEmptyFieldRemovesTheLastTag() {
        let result = TagInputFieldLogic.typing("", after: marker, tags: ["vegan", "quick"])

        #expect(result.tags == ["vegan"])
        #expect(result.text == marker)
    }

    @Test func deleteWithNoTagsOnlyRestoresTheMarker() {
        let result = TagInputFieldLogic.typing("", after: marker, tags: [])

        #expect(result.tags.isEmpty)
        #expect(result.text == marker)
    }

    @Test func deletingTypedTextRemovesNoTag() {
        let result = TagInputFieldLogic.typing(marker, after: "\(marker)a", tags: ["vegan"])

        #expect(result.tags == ["vegan"])
        #expect(result.text == marker)
    }

    @Test func applyingAResultAgainChangesNothing() {
        let first = TagInputFieldLogic.typing("spicy,", after: "spicy", tags: ["vegan"])
        let second = TagInputFieldLogic.typing(first.text, after: "spicy,", tags: first.tags)

        #expect(second.tags == first.tags)
        #expect(second.text == first.text)
    }

    @Test func theFieldTakesTheRestOfTheLine() {
        let sizes = [CGSize(width: 80, height: 32), CGSize(width: 60, height: 32), CGSize(width: 10, height: 32)]
        let frames = TagInputFieldLogic.frames(sizes: sizes, width: 300, spacing: 8, fieldMinWidth: 96)

        #expect(frames[1].minX == 88)
        #expect(frames[2] == CGRect(x: 156, y: 0, width: 144, height: 32))
    }

    @Test func theFieldMovesToANewLineWhenItDoesNotFit() {
        let sizes = [CGSize(width: 120, height: 32), CGSize(width: 110, height: 32), CGSize(width: 10, height: 32)]
        let frames = TagInputFieldLogic.frames(sizes: sizes, width: 300, spacing: 8, fieldMinWidth: 96)

        #expect(frames[2] == CGRect(x: 0, y: 40, width: 300, height: 32))
    }

    @Test func tagsWrapAndALongOneIsCutToTheWidth() {
        let sizes = [CGSize(width: 200, height: 32), CGSize(width: 500, height: 32), CGSize(width: 10, height: 32)]
        let frames = TagInputFieldLogic.frames(sizes: sizes, width: 300, spacing: 8, fieldMinWidth: 96)

        #expect(frames[1] == CGRect(x: 0, y: 40, width: 300, height: 32))
        #expect(frames[2].minY == 80)
    }

    @Test func anEmptyFieldFillsTheWidth() {
        let frames = TagInputFieldLogic.frames(sizes: [CGSize(width: 10, height: 32)], width: 300, spacing: 8, fieldMinWidth: 96)

        #expect(frames == [CGRect(x: 0, y: 0, width: 300, height: 32)])
    }
}
