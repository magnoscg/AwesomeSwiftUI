// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct MaskedTextFieldTests {
    @Test func insertsLiteralsBetweenDigits() {
        #expect(MaskedTextFieldFormatter.format("1234", mask: "##/##") == "12/34")
    }

    @Test func addsALiteralOnlyWhenACharacterFollows() {
        #expect(MaskedTextFieldFormatter.format("12", mask: "##/##") == "12")
        #expect(MaskedTextFieldFormatter.format("123", mask: "##/##") == "12/3")
    }

    @Test func backspaceOverALiteralDoesNotComeBack() {
        #expect(MaskedTextFieldFormatter.format("12/", mask: "##/##") == "12")
    }

    @Test func formattingIsStable() {
        let once = MaskedTextFieldFormatter.format("6125550199", mask: "(###) ###-####")

        #expect(once == "(612) 555-0199")
        #expect(MaskedTextFieldFormatter.format(once, mask: "(###) ###-####") == once)
    }

    @Test func aLeadingLiteralWithDigitsIsNotRead() {
        let once = MaskedTextFieldFormatter.format("6", mask: "+34 ### ###")

        #expect(once == "+34 6")
        #expect(MaskedTextFieldFormatter.format(once + "1", mask: "+34 ### ###") == "+34 61")
    }

    @Test func dropsCharactersTheMaskRejects() {
        #expect(MaskedTextFieldFormatter.format("a1b2c3", mask: "###") == "123")
        #expect(MaskedTextFieldFormatter.format("x9y", mask: "A#A") == "x9y")
    }

    @Test func stopsAtTheEndOfTheMask() {
        #expect(MaskedTextFieldFormatter.format("123456789", mask: "##/##") == "12/34")
    }

    @Test func emptyValuesDoNotCrash() {
        #expect(MaskedTextFieldFormatter.format("", mask: "##") == "")
        #expect(MaskedTextFieldFormatter.format("abc", mask: "") == "abc")
        #expect(!MaskedTextFieldFormatter.isComplete("abc", mask: ""))
    }

    @Test func knowsWhenTheMaskIsFull() {
        #expect(MaskedTextFieldFormatter.isComplete("12/34", mask: "##/##"))
        #expect(!MaskedTextFieldFormatter.isComplete("12/3", mask: "##/##"))
    }

    @Test func aDigitInsideALeadingLiteralCanStillBeTyped() {
        #expect(MaskedTextFieldFormatter.format("3", mask: "+34 ### ###") == "+34 3")
        #expect(MaskedTextFieldFormatter.format("4", mask: "+34 ### ###") == "+34 4")
    }

    @Test func aCompletePrefixIsReadBackWithoutItsSeparator() {
        #expect(MaskedTextFieldFormatter.format("+34612345678", mask: "+34 ### ### ###") == "+34 612 345 678")
    }

    @Test func digitsThatAreNotAPrefixStayAsData() {
        #expect(MaskedTextFieldFormatter.format("34", mask: "+34 ### ###") == "+34 34")
        #expect(MaskedTextFieldFormatter.format("346123", mask: "+34 ### ###") == "+34 346 123")
    }

    @Test func aPrefixMadeOnlyOfDataIsNotReadWithoutItsSeparator() {
        #expect(MaskedTextFieldFormatter.format("1", mask: "1 (###)") == "1 (1")
    }

    @Test func aWholeLeadingLiteralIsReadBack() {
        #expect(MaskedTextFieldFormatter.format("+34 3", mask: "+34 ### ###") == "+34 3")
        #expect(MaskedTextFieldFormatter.format("+34 ", mask: "+34 ### ###") == "")
    }
}
