// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct SwipeToConfirmSliderTests {
    @Test func progressIsTheShareOfTheThumbTravel() {
        let progress = SwipeToConfirmSliderMath.progress(translation: 150, trackWidth: 360, thumbWidth: 60)

        #expect(progress == 0.5)
    }

    @Test func progressNeverGoesBelowZero() {
        let progress = SwipeToConfirmSliderMath.progress(translation: -40, trackWidth: 360, thumbWidth: 60)

        #expect(progress == 0)
    }

    @Test func progressNeverGoesAboveOne() {
        let progress = SwipeToConfirmSliderMath.progress(translation: 900, trackWidth: 360, thumbWidth: 60)

        #expect(progress == 1)
    }

    @Test(arguments: [0.0, 60.0, 40.0])
    func trackWithNoRoomToTravelHasNoProgress(trackWidth: Double) {
        let progress = SwipeToConfirmSliderMath.progress(translation: 100, trackWidth: trackWidth, thumbWidth: 60)

        #expect(progress == 0)
    }

    @Test func thumbOffsetFollowsProgressAcrossTheTravel() {
        let offset = SwipeToConfirmSliderMath.thumbOffset(progress: 0.25, trackWidth: 360, thumbWidth: 60)

        #expect(offset == 75)
    }

    @Test func thumbOffsetStaysInsideTheTrack() {
        let beyondEnd = SwipeToConfirmSliderMath.thumbOffset(progress: 2, trackWidth: 360, thumbWidth: 60)
        let narrowTrack = SwipeToConfirmSliderMath.thumbOffset(progress: 1, trackWidth: 40, thumbWidth: 60)

        #expect(beyondEnd == 300)
        #expect(narrowTrack == 0)
    }

    @Test func confirmsOnlyFromTheThresholdUp() {
        #expect(!SwipeToConfirmSliderMath.isConfirmed(progress: 0.91))
        #expect(SwipeToConfirmSliderMath.isConfirmed(progress: 0.92))
        #expect(SwipeToConfirmSliderMath.isConfirmed(progress: 1))
    }
}
