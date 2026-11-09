// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Testing
@testable import Showcase

struct SplitFlapCounterTests {
    @Test func padsWithZerosOnTheLeft() {
        #expect(SplitFlapCounterMath.cells(for: 5, minimumDigits: 3) == ["0", "0", "5"])
    }

    @Test func keepsTheMinusInFrontOfThePadding() {
        #expect(SplitFlapCounterMath.cells(for: -42, minimumDigits: 3) == ["-", "0", "4", "2"])
    }

    @Test(arguments: [0, -3, Int.min])
    func aMinimumBelowOneStillShowsTheNumber(minimumDigits: Int) {
        #expect(SplitFlapCounterMath.cells(for: 7, minimumDigits: minimumDigits) == ["7"])
    }

    @Test func handlesTheSmallestInteger() {
        let cells = SplitFlapCounterMath.cells(for: Int.min, minimumDigits: 1)

        #expect(cells.first == "-")
        #expect(cells.joined() == String(Int.min))
    }

    @Test func aHugeMinimumIsCapped() {
        let cells = SplitFlapCounterMath.cells(for: 1, minimumDigits: Int.max)

        #expect(cells.count == SplitFlapCounterMath.maximumDigits)
    }
}
