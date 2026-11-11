// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct MultiStepFormTests {
    @Test func invalidStepDoesNotAdvance() {
        var progress = MultiStepFormProgress()

        let didFinish = progress.advance(stepCount: 3, isCurrentStepValid: false)

        #expect(progress.index == 0)
        #expect(!didFinish)
    }

    @Test func validStepAdvances() {
        var progress = MultiStepFormProgress()

        _ = progress.advance(stepCount: 3, isCurrentStepValid: true)

        #expect(progress.index == 1)
        #expect(!progress.isFinished)
    }

    @Test func lastStepFinishesOnlyOnce() {
        var progress = MultiStepFormProgress()

        let first = progress.advance(stepCount: 1, isCurrentStepValid: true)
        let second = progress.advance(stepCount: 1, isCurrentStepValid: true)

        #expect(first)
        #expect(!second)
    }

    @Test func noStepsNeverFinishes() {
        var progress = MultiStepFormProgress()

        let didFinish = progress.advance(stepCount: 0, isCurrentStepValid: true)

        #expect(!didFinish)
        #expect(progress.index == 0)
    }

    @Test func goingBackStopsAtTheFirstStepAndReopensTheForm() {
        var progress = MultiStepFormProgress()
        _ = progress.advance(stepCount: 1, isCurrentStepValid: true)

        progress.goBack()

        #expect(progress.index == 0)
        #expect(!progress.isFinished)
    }

    @Test(arguments: [(2, 1), (0, 0), (5, 2)])
    func clampKeepsTheIndexInsideTheSteps(stepCount: Int, expected: Int) {
        var progress = MultiStepFormProgress()
        _ = progress.advance(stepCount: 5, isCurrentStepValid: true)
        _ = progress.advance(stepCount: 5, isCurrentStepValid: true)

        progress.clamp(stepCount: stepCount)

        #expect(progress.index == expected)
    }
}
