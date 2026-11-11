// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Foundation
import Testing
@testable import Showcase

struct CandlestickChartTests {
    private let day = Date(timeIntervalSinceReferenceDate: 815_000_000)

    private func candle(_ offset: Double = 0, open: Double = 100, high: Double = 110, low: Double = 95, close: Double = 105) -> CandlestickChartCandle {
        CandlestickChartCandle(date: day.addingTimeInterval(offset * 86_400), open: open, high: high, low: low, close: close)
    }

    @Test func aCandleRisesWhenItClosesAtOrAboveItsOpen() {
        #expect(candle(open: 100, close: 105).isRising)
        #expect(candle(open: 100, close: 100).isRising)
        #expect(!candle(open: 100, close: 96).isRising)
    }

    @Test func theChartGoesFromTheLowestLowToTheHighestHighWithRoom() {
        let domain = CandlestickChartMath.domain(of: [candle(high: 110, low: 90), candle(1, high: 120, low: 100)], padding: 0.1)

        #expect(domain == 87...123)
    }

    @Test func aFlatSeriesStillHasSomeHeight() {
        let domain = CandlestickChartMath.domain(of: [candle(open: 50, high: 50, low: 50, close: 50)])

        #expect(domain.lowerBound < 50)
        #expect(domain.upperBound > 50)
    }

    @Test func noCandlesGiveAPlainDomain() {
        #expect(CandlestickChartMath.domain(of: []) == 0...1)
    }

    @Test func theBodyGoesFromTheOpenToTheClose() {
        #expect(CandlestickChartMath.body(of: candle(open: 100, close: 105), minimum: 1) == 100...105)
        #expect(CandlestickChartMath.body(of: candle(open: 105, close: 100), minimum: 1) == 100...105)
    }

    @Test func aDayThatClosedWhereItOpenedKeepsAThinBody() {
        #expect(CandlestickChartMath.body(of: candle(open: 100, close: 100), minimum: 1) == 99.5...100.5)
        #expect(CandlestickChartMath.body(of: candle(open: 100, close: 100.4), minimum: 1) == 99.7...100.7)
    }

    @Test func theChangeIsAShareOfTheOpen() {
        #expect(CandlestickChartMath.change(of: candle(open: 100, close: 105)) == 0.05)
        #expect(CandlestickChartMath.change(of: candle(open: 200, close: 190)) == -0.05)
        #expect(CandlestickChartMath.change(of: candle(open: 0, close: 5)) == 0)
    }

    @Test func aTouchPicksTheClosestDay() throws {
        let candles = [candle(0), candle(1), candle(2)]

        let picked = try #require(CandlestickChartMath.nearest(to: day.addingTimeInterval(1.4 * 86_400), in: candles))

        #expect(picked == candles[1])
        #expect(CandlestickChartMath.nearest(to: day.addingTimeInterval(-9 * 86_400), in: candles) == candles[0])
        #expect(CandlestickChartMath.nearest(to: day, in: []) == nil)
    }
}
