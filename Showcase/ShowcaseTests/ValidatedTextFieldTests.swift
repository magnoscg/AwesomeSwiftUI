// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct ValidatedTextFieldTests {
    private func required(_ value: String) -> String? {
        value.isEmpty ? "Required" : nil
    }

    @Test func typingNeverRaisesAnError() {
        var feedback = ValidatedTextFieldFeedback()

        feedback.textChanged(text: "", validate: required)

        #expect(feedback.message == nil)
    }

    @Test func losingFocusShowsTheError() {
        var feedback = ValidatedTextFieldFeedback()

        feedback.fieldLostFocus(text: "", validate: required)

        #expect(feedback.message == "Required")
    }

    @Test func fixingTheTextClearsTheErrorRightAway() {
        var feedback = ValidatedTextFieldFeedback()
        feedback.fieldLostFocus(text: "", validate: required)

        feedback.textChanged(text: "a", validate: required)

        #expect(feedback.message == nil)
    }

    @Test func anErrorDoesNotComeBackWhileTyping() {
        var feedback = ValidatedTextFieldFeedback()
        feedback.fieldLostFocus(text: "fine", validate: required)

        feedback.textChanged(text: "", validate: required)

        #expect(feedback.message == nil)
    }
}
