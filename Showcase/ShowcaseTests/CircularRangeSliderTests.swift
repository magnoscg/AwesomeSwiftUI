// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import CoreGraphics
import Testing
@testable import Showcase

struct CircularRangeSliderTests {
    private let size = CGSize(width: 200, height: 200)

    @Test func turnsStartAtTwelveAndGrowClockwise() {
        #expect(CircularRangeSliderMath.turn(at: CGPoint(x: 100, y: 0), in: size) == 0)
        #expect(CircularRangeSliderMath.turn(at: CGPoint(x: 200, y: 100), in: size) == 0.25)
        #expect(CircularRangeSliderMath.turn(at: CGPoint(x: 100, y: 200), in: size) == 0.5)
        #expect(CircularRangeSliderMath.turn(at: CGPoint(x: 0, y: 100), in: size) == 0.75)
    }

    @Test func theCenterHasNoTurn() {
        #expect(CircularRangeSliderMath.turn(at: CGPoint(x: 100, y: 100), in: size) == 0)
    }

    @Test func aHandleSitsInTheMiddleOfTheLine() {
        let top = CircularRangeSliderMath.point(atTurn: 0, in: size, lineWidth: 40)
        let right = CircularRangeSliderMath.point(atTurn: 0.25, in: size, lineWidth: 40)

        #expect(abs(top.x - 100) < 0.001 && abs(top.y - 20) < 0.001)
        #expect(abs(right.x - 180) < 0.001 && abs(right.y - 100) < 0.001)
    }

    @Test func valuesWrapAroundTheDial() {
        #expect(CircularRangeSliderMath.wrapped(25, total: 24) == 1)
        #expect(CircularRangeSliderMath.wrapped(-1, total: 24) == 23)
        #expect(CircularRangeSliderMath.wrapped(24, total: 24) == 0)
    }

    @Test func valuesSnapToTheStep() {
        #expect(CircularRangeSliderMath.wrapped(7.1, total: 24, step: 0.25) == 7)
        #expect(CircularRangeSliderMath.wrapped(7.2, total: 24, step: 0.25) == 7.25)
        #expect(CircularRangeSliderMath.wrapped(23.9, total: 24, step: 0.25) == 0)
    }

    @Test func valuesThatMakeNoSenseBecomeZero() {
        #expect(CircularRangeSliderMath.wrapped(.nan, total: 24) == 0)
        #expect(CircularRangeSliderMath.wrapped(5, total: 0) == 0)
    }

    @Test func aRangeCanCrossTwelve() {
        #expect(CircularRangeSliderMath.span(from: 23, to: 7, total: 24) == 8)
        #expect(CircularRangeSliderMath.span(from: 7, to: 23, total: 24) == 16)
        #expect(CircularRangeSliderMath.span(from: 5, to: 5, total: 24) == 0)
    }

    @Test func aRangeKeepsItsMinimumAndLeavesAsMuchFree() {
        #expect(CircularRangeSliderMath.allows(span: 1, from: 2, total: 24, minimumSpan: 1))
        #expect(!CircularRangeSliderMath.allows(span: 0.75, from: 1, total: 24, minimumSpan: 1))
        #expect(CircularRangeSliderMath.allows(span: 23, from: 22, total: 24, minimumSpan: 1))
        #expect(!CircularRangeSliderMath.allows(span: 23.25, from: 23, total: 24, minimumSpan: 1))
    }

    @Test func aHandleCannotJumpOverTheOther() {
        #expect(!CircularRangeSliderMath.allows(span: 23.75, from: 0.25, total: 24, minimumSpan: 0))
        #expect(CircularRangeSliderMath.allows(span: 0, from: 0.25, total: 24, minimumSpan: 0))
    }

    @Test func aTouchOnAHandleTakesThatHandle() {
        let part = CircularRangeSliderMath.part(at: CGPoint(x: 178, y: 104), in: size, startTurn: 0, endTurn: 0.25, lineWidth: 40)

        #expect(part == .end)
        #expect(CircularRangeSliderMath.part(at: CGPoint(x: 100, y: 22), in: size, startTurn: 0, endTurn: 0.25, lineWidth: 40) == .start)
    }

    @Test func aTouchOnTheRangeTakesBothHandles() {
        let middle = CircularRangeSliderMath.point(atTurn: 0.25, in: size, lineWidth: 40)

        #expect(CircularRangeSliderMath.part(at: middle, in: size, startTurn: 0, endTurn: 0.5, lineWidth: 40) == .both)
    }

    @Test func aTouchElsewhereTakesNothing() {
        let outsideTheRange = CircularRangeSliderMath.point(atTurn: 0.75, in: size, lineWidth: 40)

        #expect(CircularRangeSliderMath.part(at: outsideTheRange, in: size, startTurn: 0, endTurn: 0.5, lineWidth: 40) == nil)
        #expect(CircularRangeSliderMath.part(at: CGPoint(x: 100, y: 100), in: size, startTurn: 0, endTurn: 0.5, lineWidth: 40) == nil)
    }

    @Test func whereTheHandlesMeetTheEndWins() {
        let shared = CircularRangeSliderMath.point(atTurn: 0.4, in: size, lineWidth: 40)

        #expect(CircularRangeSliderMath.part(at: shared, in: size, startTurn: 0.4, endTurn: 0.4, lineWidth: 40) == .end)
    }
}
