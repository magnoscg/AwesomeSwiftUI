// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct ScrambleTextTests {
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64

        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var mixed = state
            mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
            mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
            return mixed ^ (mixed >> 31)
        }
    }

    private func scrambled(_ text: String, progress: Double, characters: [Character] = ["#"], seed: UInt64 = 1) -> String {
        var generator = SeededGenerator(state: seed)
        return ScrambleTextScrambler.scrambled(text, progress: progress, characters: characters, using: &generator)
    }

    @Test func atTheStartEveryLetterIsReplaced() {
        #expect(scrambled("ABCD", progress: 0) == "####")
    }

    @Test func atTheEndTheTextIsFinal() {
        #expect(scrambled("Hello there", progress: 1) == "Hello there")
    }

    @Test func lettersSettleFromTheLeft() {
        #expect(scrambled("ABCD", progress: 0.5) == "AB##")
    }

    @Test func aLetterSettlesOnlyOnceItsShareIsComplete() {
        #expect(scrambled("ABCD", progress: 0.74) == "AB##")
        #expect(scrambled("ABCD", progress: 0.75) == "ABC#")
    }

    @Test func whitespaceIsNeverScrambled() {
        #expect(scrambled("A B\nC", progress: 0) == "# #\n#")
    }

    @Test(arguments: [-1, Double.nan])
    func invalidProgressActsAsTheStart(progress: Double) {
        #expect(scrambled("AB", progress: progress) == "##")
    }

    @Test func progressBeyondTheEndActsAsTheEnd() {
        #expect(scrambled("AB", progress: 7) == "AB")
    }

    @Test func noCharactersToPickFromLeavesTheText() {
        #expect(scrambled("AB", progress: 0, characters: []) == "AB")
    }

    @Test func keepsTheCharacterCountWithEmoji() {
        let text = "Hi 👩‍💻🇪🇸!"

        #expect(scrambled(text, progress: 0.5).count == text.count)
    }

    @Test func theSameSeedGivesTheSameResult() {
        let characters = ScrambleTextScrambler.defaultCharacters

        #expect(
            scrambled("A long enough sentence", progress: 0.2, characters: characters, seed: 42)
                == scrambled("A long enough sentence", progress: 0.2, characters: characters, seed: 42)
        )
    }

    @Test func differentSeedsGiveDifferentResults() {
        let characters = ScrambleTextScrambler.defaultCharacters

        #expect(
            scrambled("A long enough sentence", progress: 0, characters: characters, seed: 1)
                != scrambled("A long enough sentence", progress: 0, characters: characters, seed: 2)
        )
    }

    @Test func picksOnlyFromTheGivenCharacters() {
        let result = scrambled("ABCDEFGHIJ", progress: 0, characters: ["x", "y"], seed: 3)

        #expect(result.allSatisfy { $0 == "x" || $0 == "y" })
    }
}
