// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI
import Testing
@testable import Showcase

struct RippleShaderEffectTests {
    @Test func aWaveFromTheCenterTravelsToTheCorners() {
        let reach = RippleShaderEffectMath.reach(from: CGPoint(x: 3, y: 4), in: CGSize(width: 6, height: 8), wavelength: 0)

        #expect(reach == 5)
    }

    @Test func aWaveFromACornerCrossesTheDiagonal() {
        let reach = RippleShaderEffectMath.reach(from: .zero, in: CGSize(width: 30, height: 40), wavelength: 0)

        #expect(reach == 50)
    }

    @Test func aWaveFromOutsideStillCrossesTheView() {
        let reach = RippleShaderEffectMath.reach(from: CGPoint(x: -30, y: 0), in: CGSize(width: 30, height: 80), wavelength: 0)

        #expect(reach == 100)
    }

    @Test func theWholeWidthOfTheWaveLeavesTheView() {
        let reach = RippleShaderEffectMath.reach(from: CGPoint(x: 3, y: 4), in: CGSize(width: 6, height: 8), wavelength: 20)

        #expect(reach == 25)
    }

    @Test func aNegativeWavelengthAddsNothing() {
        let reach = RippleShaderEffectMath.reach(from: CGPoint(x: 3, y: 4), in: CGSize(width: 6, height: 8), wavelength: -20)

        #expect(reach == 5)
    }

    @Test func travelTimeFollowsTheSpeed() {
        #expect(RippleShaderEffectMath.travelTime(reach: 600, speed: 300) == 2)
    }

    @Test(arguments: [0.0, -300.0])
    func aWaveThatCannotMoveLastsOneFrame(speed: Double) {
        #expect(RippleShaderEffectMath.travelTime(reach: 600, speed: speed) == 1.0 / 60.0)
    }

    @Test func aViewWithNoSizeStillGetsValidTiming() {
        let reach = RippleShaderEffectMath.reach(from: .zero, in: .zero, wavelength: 0)

        #expect(RippleShaderEffectMath.travelTime(reach: reach, speed: 650) == 1.0 / 60.0)
    }

    @Test func aStillWaveKeepsItsStrengthAtTheOrigin() {
        let wave = RippleShaderEffectWave(radius: 320, strength: 0.4)

        #expect(wave.still == RippleShaderEffectWave(radius: 0, strength: 0.4))
    }

    @Test func theShaderCompilesAsALayerEffect() async throws {
        let wave = RippleShaderEffectWave(radius: 40, strength: 1)
        let shader = RippleShaderEffectMath.shader(wave: wave, origin: CGPoint(x: 20, y: 20), amplitude: 10, wavelength: 110)

        try await shader.compile(as: .layerEffect)
    }
}
