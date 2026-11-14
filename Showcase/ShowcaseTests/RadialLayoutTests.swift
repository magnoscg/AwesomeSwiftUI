// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI
import Testing
@testable import Showcase

struct RadialLayoutTests {
    @Test func noViewsGiveNoAngles() {
        #expect(RadialLayoutMath.angles(count: 0).isEmpty)
    }

    @Test func theFirstViewSitsAtTheStartAngle() throws {
        let first = try #require(RadialLayoutMath.angles(count: 5, start: .degrees(30)).first)

        #expect(abs(first.degrees - 30) < 0.0001)
    }

    @Test(arguments: [2, 3, 5, 8, 12])
    func anglesAreEvenlySpaced(count: Int) {
        let degrees = RadialLayoutMath.angles(count: count).map(\.degrees)

        for (current, next) in zip(degrees, degrees.dropFirst()) {
            #expect(abs(next - current - 360 / Double(count)) < 0.0001)
        }
    }

    @Test func theLastAngleStopsShortOfACompleteTurn() throws {
        let start = -90.0
        let last = try #require(RadialLayoutMath.angles(count: 4, start: .degrees(start)).last)

        #expect(abs(last.degrees - (start + 270)) < 0.0001)
    }

    @Test func fourViewsLandOnTheCardinalPoints() {
        let center = CGPoint(x: 100, y: 100)
        let points = RadialLayoutMath.angles(count: 4).map { RadialLayoutMath.point(at: $0, center: center, radius: 50) }
        let expected = [CGPoint(x: 100, y: 50), CGPoint(x: 150, y: 100), CGPoint(x: 100, y: 150), CGPoint(x: 50, y: 100)]

        for (point, target) in zip(points, expected) {
            #expect(abs(point.x - target.x) < 0.0001)
            #expect(abs(point.y - target.y) < 0.0001)
        }
    }
}
