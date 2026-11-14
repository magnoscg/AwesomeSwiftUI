// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI
import Testing
@testable import Showcase

struct HolographicCardTests {
    private let size = CGSize(width: 300, height: 400)

    @Test func aCardNobodyDragsStaysFlat() {
        #expect(HolographicCardMath.tilt(for: .zero, in: size) == .zero)
    }

    @Test func draggingHalfTheCardLeansItAllTheWay() {
        let tilt = HolographicCardMath.tilt(for: CGSize(width: 150, height: 200), in: size)

        #expect(tilt == CGSize(width: 1, height: 1))
    }

    @Test func aShorterDragLeansItInProportion() {
        let tilt = HolographicCardMath.tilt(for: CGSize(width: 75, height: -50), in: size)

        #expect(tilt == CGSize(width: 0.5, height: -0.25))
    }

    @Test func aLongerDragLeansItNoFurther() {
        let tilt = HolographicCardMath.tilt(for: CGSize(width: 900, height: -900), in: size)

        #expect(tilt == CGSize(width: 1, height: -1))
    }

    @Test(arguments: [CGSize.zero, CGSize(width: 300, height: 0), CGSize(width: 0, height: 400)])
    func aCardWithNoSizeStaysFlat(size: CGSize) {
        #expect(HolographicCardMath.tilt(for: CGSize(width: 80, height: 80), in: size) == .zero)
    }

    @Test func aLeanTurnsTheCardInProportion() {
        #expect(HolographicCardMath.yaw(for: 0.5, maxAngle: 16, layoutDirection: .leftToRight) == 8)
    }

    @Test func aRightToLeftLayoutTurnsTheCardTheOtherWay() {
        #expect(HolographicCardMath.yaw(for: 0.5, maxAngle: 16, layoutDirection: .rightToLeft) == -8)
    }

    @Test func theShaderCompilesAsAColorEffect() async throws {
        let shader = HolographicCardMath.shader(size: size, tilt: CGSize(width: 0.5, height: -0.5), intensity: 1)

        try await shader.compile(as: .colorEffect)
    }
}
