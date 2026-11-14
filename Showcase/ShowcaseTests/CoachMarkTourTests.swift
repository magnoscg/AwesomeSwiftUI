// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

@Suite struct CoachMarkTourTests {
    @Test func advancesThroughTheSteps() {
        var progress = CoachMarkTourProgress()

        let finished = progress.advance(stepCount: 3)

        #expect(finished == false)
        #expect(progress.index == 1)
    }

    @Test func theLastStepFinishesTheTour() {
        var progress = CoachMarkTourProgress()
        _ = progress.advance(stepCount: 2)

        let finished = progress.advance(stepCount: 2)

        #expect(finished)
        #expect(progress.isFinished)
    }

    @Test func finishingReportsOnlyOnce() {
        var progress = CoachMarkTourProgress()
        let first = progress.finish()

        let second = progress.finish()
        let third = progress.advance(stepCount: 3)

        #expect(first)
        #expect(second == false)
        #expect(third == false)
    }

    @Test func noStepsFinishesAtOnce() {
        var progress = CoachMarkTourProgress()

        let finished = progress.advance(stepCount: 0)

        #expect(finished)
    }

    @Test func clampingKeepsTheIndexValidWhenStepsShrink() {
        var progress = CoachMarkTourProgress()
        _ = progress.advance(stepCount: 5)
        _ = progress.advance(stepCount: 5)

        progress.clamp(stepCount: 1)

        #expect(progress.index == 0)
    }

    @Test func clampingEmptyStepsDoesNotGoNegative() {
        var progress = CoachMarkTourProgress()

        progress.clamp(stepCount: 0)

        #expect(progress.index == 0)
    }

    @Test func restartGoesBackToTheBeginning() {
        var progress = CoachMarkTourProgress()
        _ = progress.advance(stepCount: 3)
        _ = progress.finish()

        progress.restart()

        #expect(progress == CoachMarkTourProgress())
    }
}
