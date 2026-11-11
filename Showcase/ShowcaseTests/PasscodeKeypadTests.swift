// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct PasscodeKeypadTests {
    @Test func aDigitIsAddedAtTheEnd() {
        #expect(PasscodeKeypadLogic.adding(5, to: "12", length: 4) == "125")
        #expect(PasscodeKeypadLogic.adding(0, to: "", length: 4) == "0")
    }

    @Test func aFullCodeTakesNoMoreDigits() {
        #expect(PasscodeKeypadLogic.adding(7, to: "1234", length: 4) == "1234")
        #expect(PasscodeKeypadLogic.adding(7, to: "", length: 0) == "")
    }

    @Test func onlySingleDigitsAreAdded() {
        #expect(PasscodeKeypadLogic.adding(10, to: "1", length: 4) == "1")
        #expect(PasscodeKeypadLogic.adding(-1, to: "1", length: 4) == "1")
    }

    @Test func theKeysGoFromOneToNine() {
        #expect(PasscodeKeypadLogic.rows.flatMap { $0 } == Array(1...9))
    }

    @Test func theDotsStartAndEndInPlace() {
        #expect(PasscodeKeypadLogic.shake(at: 0) == 0)
        #expect(PasscodeKeypadLogic.shake(at: 1) == 0)
        #expect(PasscodeKeypadLogic.shake(at: 1.4) == 0)
        #expect(PasscodeKeypadLogic.shake(at: -0.2) == 0)
    }

    @Test func theDotsSwingToBothSides() throws {
        let offsets = stride(from: 0.0, through: 1, by: 0.02).map { PasscodeKeypadLogic.shake(at: $0) }
        let farthestRight = try #require(offsets.max())
        let farthestLeft = try #require(offsets.min())

        #expect(farthestRight > 6)
        #expect(farthestLeft < -6)
    }

    @Test func theSwingsNeverPassTheAmplitude() {
        let offsets = stride(from: 0.0, through: 1, by: 0.01).map { PasscodeKeypadLogic.shake(at: $0, amplitude: 20) }

        #expect(offsets.allSatisfy { abs($0) <= 20 })
    }

    @Test func theSwingsGetShorter() {
        let early = abs(PasscodeKeypadLogic.shake(at: 1.0 / 12))
        let late = abs(PasscodeKeypadLogic.shake(at: 11.0 / 12))

        #expect(early > late)
    }
}
