// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Testing
@testable import Showcase

struct StoriesViewerTests {
    @Test func tickingFillsTheCurrentSegment() {
        var playback = StoriesViewerPlayback()

        playback.tick(elapsed: 1, duration: 4, count: 3)

        #expect(playback.index == 0)
        #expect(playback.progress == 0.25)
    }

    @Test func aFullSegmentMovesToTheNextStory() {
        var playback = StoriesViewerPlayback()

        playback.tick(elapsed: 4, duration: 4, count: 3)

        #expect(playback.index == 1)
        #expect(playback.progress == 0)
    }

    @Test func theLastStoryFinishesAndStaysFull() {
        var playback = StoriesViewerPlayback()

        playback.next(count: 1)
        playback.tick(elapsed: 10, duration: 4, count: 1)

        #expect(playback.isFinished)
        #expect(playback.index == 0)
        #expect(playback.fill(for: 0) == 1)
    }

    @Test func goingBackFromTheEndClearsTheFinish() {
        var playback = StoriesViewerPlayback()
        playback.next(count: 2)
        playback.next(count: 2)

        playback.previous(count: 2)

        #expect(!playback.isFinished)
        #expect(playback.index == 0)
    }

    @Test func goingBackOnTheFirstStoryRestartsIt() {
        var playback = StoriesViewerPlayback()
        playback.tick(elapsed: 1, duration: 4, count: 3)

        playback.previous(count: 3)

        #expect(playback.index == 0)
        #expect(playback.progress == 0)
    }

    @Test func nothingHappensWithoutStories() {
        var playback = StoriesViewerPlayback()

        playback.tick(elapsed: 10, duration: 4, count: 0)
        playback.next(count: 0)

        #expect(playback == StoriesViewerPlayback())
    }

    @Test(arguments: [0.0, -5.0])
    func aZeroOrNegativeDurationStillAdvances(duration: Double) {
        var playback = StoriesViewerPlayback()

        playback.tick(elapsed: 1, duration: duration, count: 2)

        #expect(playback.index == 1)
    }

    @Test func aShorterListMovesThePositionBackInside() {
        var playback = StoriesViewerPlayback()
        playback.next(count: 5)
        playback.next(count: 5)

        playback.clamp(count: 2)

        #expect(playback.index == 1)
    }

    @Test func segmentsBeforeAreFullAndSegmentsAfterAreEmpty() {
        var playback = StoriesViewerPlayback()
        playback.next(count: 3)
        playback.tick(elapsed: 1, duration: 2, count: 3)

        #expect(playback.fill(for: 0) == 1)
        #expect(playback.fill(for: 1) == 0.5)
        #expect(playback.fill(for: 2) == 0)
    }

    @Test func newStoriesAfterTheEndResumePlayback() {
        var playback = StoriesViewerPlayback()
        playback.next(count: 1)

        playback.clamp(count: 2)

        #expect(!playback.isFinished)
        #expect(playback.index == 1)
        #expect(playback.progress == 0)
    }

    @Test func aFinishedListWithNothingNewStaysFinished() {
        var playback = StoriesViewerPlayback()
        playback.next(count: 1)

        playback.clamp(count: 1)

        #expect(playback.isFinished)
        #expect(playback.index == 0)
    }
}
