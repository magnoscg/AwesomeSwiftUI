// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import CoreGraphics
import Testing
@testable import Showcase

struct RadarChartTests {
    private let center = CGPoint(x: 100, y: 100)

    private func isClose(_ point: CGPoint, _ x: Double, _ y: Double) -> Bool {
        abs(point.x - x) < 0.000_001 && abs(point.y - y) < 0.000_001
    }

    @Test func theFirstAxisPointsUpAndTheRestGoClockwise() {
        #expect(isClose(RadarChartMath.point(axis: 0, count: 4, share: 1, center: center, radius: 50), 100, 50))
        #expect(isClose(RadarChartMath.point(axis: 1, count: 4, share: 1, center: center, radius: 50), 150, 100))
        #expect(isClose(RadarChartMath.point(axis: 2, count: 4, share: 1, center: center, radius: 50), 100, 150))
        #expect(isClose(RadarChartMath.point(axis: 3, count: 4, share: 1, center: center, radius: 50), 50, 100))
    }

    @Test func aShareOfZeroIsTheCenter() {
        #expect(isClose(RadarChartMath.point(axis: 2, count: 5, share: 0, center: center, radius: 50), 100, 100))
    }

    @Test func aValueBecomesAShareOfTheMaximum() {
        #expect(RadarChartMath.share(of: 50, maximum: 100) == 0.5)
        #expect(RadarChartMath.share(of: 100, maximum: 100) == 1)
    }

    @Test func aValueOutsideTheScaleStaysOnTheAxis() {
        #expect(RadarChartMath.share(of: 140, maximum: 100) == 1)
        #expect(RadarChartMath.share(of: -20, maximum: 100) == 0)
        #expect(RadarChartMath.share(of: .nan, maximum: 100) == 0)
        #expect(RadarChartMath.share(of: 50, maximum: 0) == 0)
    }

    @Test func aSeriesHasACornerPerAxis() {
        let corners = RadarChartMath.corners(values: [100, 50, 100, 50], axes: 4, maximum: 100, center: center, radius: 50)

        #expect(corners.count == 4)
        #expect(isClose(corners[0], 100, 50))
        #expect(isClose(corners[1], 125, 100))
    }

    @Test func missingValuesSitAtTheCenter() {
        let corners = RadarChartMath.corners(values: [100], axes: 3, maximum: 100, center: center, radius: 50)

        #expect(corners.count == 3)
        #expect(isClose(corners[1], 100, 100))
        #expect(isClose(corners[2], 100, 100))
    }

    @Test func noAxesGiveNoCorners() {
        #expect(RadarChartMath.corners(values: [1, 2], axes: 0, maximum: 100, center: center, radius: 50).isEmpty)
        #expect(RadarChartMath.angle(of: 0, count: 0).isFinite)
    }

    @Test func theShapeOfASeriesGrowsFromTheCenter() {
        let rect = CGRect(x: 0, y: 0, width: 200, height: 200)
        let small = RadarChartShape(values: [100, 100, 100], axes: 3, maximum: 100, growth: 0.5).path(in: rect).boundingRect
        let full = RadarChartShape(values: [100, 100, 100], axes: 3, maximum: 100, growth: 1).path(in: rect).boundingRect

        #expect(small.height < full.height)
        #expect(abs(full.minY) < 0.000_001)
    }

    @Test func aChartWithFewerThanThreeAxesDrawsNothing() {
        let rect = CGRect(x: 0, y: 0, width: 200, height: 200)

        #expect(RadarChartGrid(axes: 2, rings: 4).path(in: rect).isEmpty)
        #expect(RadarChartShape(values: [1, 2], axes: 2, maximum: 100, growth: 1).path(in: rect).isEmpty)
    }
}
