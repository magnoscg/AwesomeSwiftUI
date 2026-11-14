// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import CoreGraphics
import Foundation
import SwiftUI
import Testing
@testable import Showcase

struct Globe3DWireframeTests {
    private let tolerance = 0.000_001

    @Test func theFrontOfTheGlobeFacesTheViewer() {
        let point = Globe3DWireframeMath.project(latitude: 0, longitude: 0, yaw: 0, pitch: 0)

        #expect(abs(point.x) < tolerance)
        #expect(abs(point.y) < tolerance)
        #expect(abs(point.z - 1) < tolerance)
    }

    @Test func theNorthPoleIsAtTheTop() {
        let point = Globe3DWireframeMath.project(latitude: 90, longitude: 0, yaw: 0, pitch: 0)

        #expect(abs(point.y - 1) < tolerance)
    }

    @Test func aPositiveYawMovesTheFrontToTheRight() {
        let point = Globe3DWireframeMath.project(latitude: 0, longitude: 0, yaw: .pi / 2, pitch: 0)

        #expect(abs(point.x - 1) < tolerance)
        #expect(abs(point.z) < tolerance)
    }

    @Test func aPositivePitchBringsTheNorthPoleForward() {
        let point = Globe3DWireframeMath.project(latitude: 90, longitude: 0, yaw: 0, pitch: 1)

        #expect(point.z > 0)
        #expect(point.y > 0)
    }

    @Test(arguments: [(12.0, -40.0, 0.3, 1.1), (-80.0, 170.0, 9.5, -1.4), (0.0, 359.0, -3.0, 0.2)])
    func projectedPointsStayOnTheSphere(latitude: Double, longitude: Double, yaw: Double, pitch: Double) {
        let point = Globe3DWireframeMath.project(latitude: latitude, longitude: longitude, yaw: yaw, pitch: pitch)

        #expect(abs(point.x * point.x + point.y * point.y + point.z * point.z - 1) < tolerance)
    }

    @Test(arguments: [(3.0, 1.4), (-3.0, -1.4), (0.5, 0.5)])
    func pitchIsClamped(pitch: Double, expected: Double) {
        #expect(Globe3DWireframeMath.clampedPitch(pitch) == expected)
    }

    @Test(arguments: [
        (0.0, 0), (Double.pi, 180), (-Double.pi / 2, 270), (Double.pi * 4, 0), (Double.infinity, 0),
    ])
    func degreesWrapAround(radians: Double, expected: Int) {
        #expect(Globe3DWireframeMath.degrees(radians) == expected)
    }

    @Test(arguments: [0, -4])
    func noLinesDrawNothing(lines: Int) {
        let wires = Globe3DWireframeMath.wires(
            meridians: lines,
            parallels: lines,
            yaw: 0,
            pitch: 0,
            center: .zero,
            radius: 100
        )

        #expect(wires.front.isEmpty)
        #expect(wires.back.isEmpty)
    }

    @Test func aGlobeHasLinesOnBothSides() {
        let wires = Globe3DWireframeMath.wires(
            meridians: 6,
            parallels: 3,
            yaw: 0.4,
            pitch: 0.3,
            center: CGPoint(x: 100, y: 100),
            radius: 90
        )

        #expect(!wires.front.isEmpty)
        #expect(!wires.back.isEmpty)
    }
}
