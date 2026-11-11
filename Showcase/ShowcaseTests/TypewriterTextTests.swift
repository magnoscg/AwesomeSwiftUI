// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct TypewriterTextTests {
    @Test func nothingIsVisibleAtTheStart() {
        #expect(TypewriterTextProgress.visibleCount(elapsed: 0, charactersPerSecond: 20, total: 10) == 0)
    }

    @Test func negativeElapsedTimeShowsNothing() {
        #expect(TypewriterTextProgress.visibleCount(elapsed: -3, charactersPerSecond: 20, total: 10) == 0)
    }

    @Test func aCharacterAppearsOnlyOnceItsTimeIsComplete() {
        #expect(TypewriterTextProgress.visibleCount(elapsed: 0.49, charactersPerSecond: 10, total: 100) == 4)
        #expect(TypewriterTextProgress.visibleCount(elapsed: 0.5, charactersPerSecond: 10, total: 100) == 5)
    }

    @Test func neverShowsMoreThanTheTotal() {
        #expect(TypewriterTextProgress.visibleCount(elapsed: 60, charactersPerSecond: 20, total: 10) == 10)
    }

    @Test func anEnormousElapsedTimeDoesNotOverflow() {
        #expect(TypewriterTextProgress.visibleCount(elapsed: .greatestFiniteMagnitude, charactersPerSecond: 20, total: 10) == 10)
    }

    @Test func emptyTextHasNothingToShow() {
        #expect(TypewriterTextProgress.visibleCount(elapsed: 5, charactersPerSecond: 20, total: 0) == 0)
    }

    @Test(arguments: [0.0, -5.0])
    func aSpeedThatCannotProgressShowsEverything(speed: Double) {
        #expect(TypewriterTextProgress.visibleCount(elapsed: 0, charactersPerSecond: speed, total: 10) == 10)
    }

    @Test func countsWholeCharactersEvenWithEmoji() {
        let text = "Hi 👩‍💻🇪🇸!"

        let count = TypewriterTextProgress.visibleCount(elapsed: 4, charactersPerSecond: 1, total: text.count)

        #expect(String(text.prefix(count)) == "Hi 👩‍💻")
    }
}
