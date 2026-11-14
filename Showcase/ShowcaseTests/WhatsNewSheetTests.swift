// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct WhatsNewSheetTests {
    @Test func aLaterVersionIsNewer() {
        #expect(WhatsNewSheetLogic.isNewer("2.4", than: "2.3"))
        #expect(WhatsNewSheetLogic.isNewer("3.0", than: "2.9.9"))
        #expect(WhatsNewSheetLogic.isNewer("2.3.1", than: "2.3"))
    }

    @Test func numbersAreComparedAsNumbers() {
        #expect(WhatsNewSheetLogic.isNewer("2.10", than: "2.9"))
        #expect(!WhatsNewSheetLogic.isNewer("2.9", than: "2.10"))
    }

    @Test func theSameVersionIsNotNewer() {
        #expect(!WhatsNewSheetLogic.isNewer("2.4", than: "2.4"))
        #expect(!WhatsNewSheetLogic.isNewer("2.0", than: "2"))
        #expect(!WhatsNewSheetLogic.isNewer("2", than: "2.0.0"))
    }

    @Test func anEarlierVersionIsNotNewer() {
        #expect(!WhatsNewSheetLogic.isNewer("1.9", than: "2.0"))
    }

    @Test func anyVersionIsNewerThanNoneShown() {
        #expect(WhatsNewSheetLogic.isNewer("1.0", than: ""))
        #expect(WhatsNewSheetLogic.isNewer("0.1", than: ""))
    }

    @Test func aVersionWithNoNumbersIsNeverNewer() {
        #expect(!WhatsNewSheetLogic.isNewer("", than: ""))
        #expect(!WhatsNewSheetLogic.isNewer("beta", than: "1.0"))
    }

    @Test func rowsComeInOneAfterAnother() {
        #expect(WhatsNewSheetLogic.delay(for: 0) == 0)
        #expect(WhatsNewSheetLogic.delay(for: 1) == 0.12)
        #expect(WhatsNewSheetLogic.delay(for: 2) == 0.24)
    }

    @Test func theLastRowsOfALongListDoNotWaitLonger() {
        #expect(WhatsNewSheetLogic.delay(for: 5) == 0.6)
        #expect(WhatsNewSheetLogic.delay(for: 40) == 0.6)
        #expect(WhatsNewSheetLogic.delay(for: -3) == 0)
    }
}
