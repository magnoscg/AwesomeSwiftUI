// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct OTPCodeFieldTests {
    @Test func keepsPlainDigits() {
        #expect(OTPCodeFieldInput.sanitized("1234", length: 6) == "1234")
    }

    @Test func removesSeparatorsFromPastedCodes() {
        #expect(OTPCodeFieldInput.sanitized("123-456", length: 6) == "123456")
        #expect(OTPCodeFieldInput.sanitized(" 12 34 ", length: 6) == "1234")
    }

    @Test func removesLetters() {
        #expect(OTPCodeFieldInput.sanitized("a1b2c3", length: 6) == "123")
    }

    @Test func rejectsDigitsOutsideASCII() {
        #expect(OTPCodeFieldInput.sanitized("١٢٣½4", length: 6) == "4")
    }

    @Test func truncatesToTheLength() {
        #expect(OTPCodeFieldInput.sanitized("12345678", length: 6) == "123456")
    }

    @Test func emptyInputStaysEmpty() {
        #expect(OTPCodeFieldInput.sanitized("", length: 6) == "")
    }

    @Test func aNegativeLengthGivesNothing() {
        #expect(OTPCodeFieldInput.sanitized("123", length: -1) == "")
    }
}
