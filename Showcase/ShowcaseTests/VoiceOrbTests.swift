// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import CoreGraphics
import Testing
@testable import Showcase

struct VoiceOrbTests {
    @Test func anIdleOrbBarelyMovesWhateverTheLevel() {
        #expect(VoiceOrbMath.energy(state: .idle, level: 0) == 0.1)
        #expect(VoiceOrbMath.energy(state: .idle, level: 1) == 0.1)
    }

    @Test func aThinkingOrbStaysHalfway() {
        #expect(VoiceOrbMath.energy(state: .thinking, level: 0.9) == 0.5)
    }

    @Test func theOrbFollowsTheVoiceWhileItListensOrSpeaks() {
        #expect(VoiceOrbMath.energy(state: .listening, level: 0) == 0.25)
        #expect(VoiceOrbMath.energy(state: .listening, level: 1) == 1)
        #expect(VoiceOrbMath.energy(state: .speaking, level: 0.5) == 0.625)
    }

    @Test func aLevelOutsideItsRangeIsClamped() {
        #expect(VoiceOrbMath.energy(state: .listening, level: 4) == 1)
        #expect(VoiceOrbMath.energy(state: .listening, level: -2) == 0.25)
        #expect(VoiceOrbMath.energy(state: .speaking, level: .nan) == 0.25)
    }

    @Test func theOrbSwellsWithItsEnergy() {
        #expect(VoiceOrbMath.scale(energy: 0) == 0.86)
        #expect(VoiceOrbMath.scale(energy: 1) == 1)
        #expect(VoiceOrbMath.scale(energy: 9) == 1)
        #expect(VoiceOrbMath.scale(energy: 0.5) > VoiceOrbMath.scale(energy: 0.2))
    }

    @Test func blobsStayInsideTheOrb() {
        for index in 0..<4 {
            for time in stride(from: 0.0, through: 20, by: 0.37) {
                let center = VoiceOrbMath.blobCenter(index: index, count: 4, time: time, energy: 1)

                #expect(hypot(center.x, center.y) <= 0.5 + 0.000_001)
            }
        }
    }

    @Test func aLivelierOrbSpreadsItsBlobs() {
        let calm = VoiceOrbMath.blobCenter(index: 0, count: 4, time: 1, energy: 0)
        let lively = VoiceOrbMath.blobCenter(index: 0, count: 4, time: 1, energy: 1)

        #expect(hypot(lively.x, lively.y) > hypot(calm.x, calm.y))
    }

    @Test func blobsStartSpreadAroundTheCenter() {
        let first = VoiceOrbMath.blobCenter(index: 0, count: 4, time: 0, energy: 0.5)
        let third = VoiceOrbMath.blobCenter(index: 2, count: 4, time: 0, energy: 0.5)

        #expect(abs(first.x + third.x) < 0.000_001)
        #expect(first.x > 0)
    }

    @Test func noBlobsStillGivesAPoint() {
        let center = VoiceOrbMath.blobCenter(index: 0, count: 0, time: 3, energy: 0.5)

        #expect(center.x.isFinite && center.y.isFinite)
    }
}
