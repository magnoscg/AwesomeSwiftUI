// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import CoreGraphics
import Testing
@testable import Showcase

struct LineChartDrawInTests {
    private let rect = CGRect(x: 0, y: 0, width: 100, height: 50)

    @Test func valuesSpanTheRect() {
        let points = LineChartDrawInLogic.points(for: [0, 10], in: rect)

        #expect(points == [CGPoint(x: 0, y: 50), CGPoint(x: 100, y: 0)])
    }

    @Test func aFlatSeriesSitsInTheMiddle() {
        let points = LineChartDrawInLogic.points(for: [7, 7], in: rect)

        #expect(points.allSatisfy { $0.y == 25 })
    }

    @Test func nothingDrawsWithoutValuesOrRoom() {
        #expect(LineChartDrawInLogic.points(for: [], in: rect).isEmpty)
        #expect(LineChartDrawInLogic.points(for: [1, 2], in: .zero).isEmpty)
        #expect(LineChartDrawInLogic.points(for: [1, 2], in: .null).isEmpty)
        #expect(LineChartDrawInLogic.points(for: [.nan, .infinity], in: rect).isEmpty)
    }

    @Test func extremeValuesStayFinite() {
        let points = LineChartDrawInLogic.points(for: [-Double.greatestFiniteMagnitude, .greatestFiniteMagnitude], in: rect)

        #expect(points.allSatisfy { $0.x.isFinite && $0.y.isFinite })
    }

    @Test func theTipMeasuresByLength() throws {
        let path = [CGPoint(x: 0, y: 0), CGPoint(x: 30, y: 0), CGPoint(x: 30, y: 10)]

        #expect(LineChartDrawInLogic.point(at: 0.75, along: path) == CGPoint(x: 30, y: 0))
        #expect(LineChartDrawInLogic.point(at: 0.5, along: path) == CGPoint(x: 20, y: 0))
    }

    @Test func progressIsClamped() {
        let path = [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 0)]

        #expect(LineChartDrawInLogic.point(at: -1, along: path) == path[0])
        #expect(LineChartDrawInLogic.point(at: 2, along: path) == path[1])
    }

    @Test func shortLinesHaveASafeTip() {
        let single = CGPoint(x: 4, y: 4)

        #expect(LineChartDrawInLogic.point(at: 0.5, along: []) == nil)
        #expect(LineChartDrawInLogic.point(at: 0.5, along: [single]) == single)
        #expect(LineChartDrawInLogic.point(at: 0.5, along: [single, single]) == single)
    }
}
