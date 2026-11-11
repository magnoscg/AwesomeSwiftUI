// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Foundation
import Testing
@testable import Showcase

struct CircularProgressRingTests {
    private let english = Locale(identifier: "en_US")

    @Test(arguments: [(-0.5, 0.0), (0.0, 0.0), (0.42, 0.42), (1.0, 1.0), (1.7, 1.0), (Double.infinity, 1.0), (-Double.infinity, 0.0)])
    func clampsToTheRing(input: Double, expected: Double) {
        #expect(CircularProgressRingMath.clamped(input) == expected)
    }

    @Test func notANumberCountsAsNoProgress() {
        #expect(CircularProgressRingMath.clamped(.nan) == 0)
        #expect(CircularProgressRingMath.wholePercent(.nan) == 0)
    }

    @Test(arguments: [(0.0, 0), (0.004, 0), (0.29, 29), (0.57, 57), (0.555, 56), (1.0, 100), (2.0, 100)])
    func roundsToTheNearestPercent(input: Double, expected: Int) {
        #expect(CircularProgressRingMath.wholePercent(input) == expected)
    }

    @Test(arguments: [0.995, 0.996, 0.9999])
    func onlyAFinishedRingReadsOneHundred(input: Double) {
        #expect(CircularProgressRingMath.wholePercent(input) == 99)
    }

    @Test func formatsWithTheGivenLocale() {
        #expect(CircularProgressRingMath.percentText(0.42, locale: english) == "42%")
        #expect(CircularProgressRingMath.percentText(0.42, locale: Locale(identifier: "es_ES")) == "42\u{a0}%")
    }

    @Test func formatsClampedValues() {
        #expect(CircularProgressRingMath.percentText(-1, locale: english) == "0%")
        #expect(CircularProgressRingMath.percentText(3, locale: english) == "100%")
    }
}
