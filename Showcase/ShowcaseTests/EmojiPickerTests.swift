// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct EmojiPickerTests {
    @Test func aNewEmojiGoesFirst() {
        #expect(EmojiPickerRecents.adding("🍕", to: ["😀"], limit: 5) == ["🍕", "😀"])
    }

    @Test func aRepeatedEmojiMovesToTheFront() {
        #expect(EmojiPickerRecents.adding("😀", to: ["🍕", "😀", "🚀"], limit: 5) == ["😀", "🍕", "🚀"])
    }

    @Test func theOldestFallOffAtTheLimit() {
        #expect(EmojiPickerRecents.adding("🚀", to: ["🍕", "😀"], limit: 2) == ["🚀", "🍕"])
    }

    @Test(arguments: [0, -3]) func aLimitOfNothingKeepsNothing(limit: Int) {
        #expect(EmojiPickerRecents.adding("🚀", to: ["🍕"], limit: limit).isEmpty)
    }

    @Test func everyCategoryHasUniqueIDsAndEmoji() {
        let categories = EmojiPickerCategory.standard

        #expect(Set(categories.map(\.id)).count == categories.count)
        for category in categories {
            #expect(Set(category.emoji).count == category.emoji.count, "\(category.title) repeats an emoji")
        }
    }
}
