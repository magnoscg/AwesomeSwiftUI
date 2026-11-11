// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Testing
@testable import Showcase

struct TabsPickerPagesTests {
    private let options = ["Overview", "Activity", "Files"]

    @Test func aLaterOptionMovesForward() {
        #expect(TabsPickerPagesLogic.movesForward(from: "Overview", to: "Files", in: options))
        #expect(TabsPickerPagesLogic.movesForward(from: "Activity", to: "Files", in: options))
    }

    @Test func anEarlierOptionMovesBack() {
        #expect(!TabsPickerPagesLogic.movesForward(from: "Files", to: "Overview", in: options))
        #expect(!TabsPickerPagesLogic.movesForward(from: "Activity", to: "Overview", in: options))
    }

    @Test func theSameOptionCountsAsForward() {
        #expect(TabsPickerPagesLogic.movesForward(from: "Activity", to: "Activity", in: options))
    }

    @Test func anOptionThatIsNotListedCountsAsTheFirst() {
        #expect(!TabsPickerPagesLogic.movesForward(from: "Files", to: "Unknown", in: options))
        #expect(TabsPickerPagesLogic.movesForward(from: "Unknown", to: "Files", in: options))
        #expect(TabsPickerPagesLogic.movesForward(from: "A", to: "B", in: [String]()))
    }
}
