// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct SparklineStatTileTests {
    @Test func theChangeComparesFirstAndLast() {
        #expect(SparklineStatTileLogic.change(in: [100, 40, 150]) == 0.5)
        #expect(SparklineStatTileLogic.change(in: [-100, -50]) == 0.5)
    }

    @Test(arguments: [[], [5], [0, 5], [.nan, .nan]] as [[Double]])
    func noChangeWhenItCannotBeComputed(values: [Double]) {
        #expect(SparklineStatTileLogic.change(in: values) == nil)
    }

    @Test func aFlatSeriesGetsAValidDomain() {
        #expect(SparklineStatTileLogic.domain(for: [3, 3]) == 2...4)
        #expect(SparklineStatTileLogic.domain(for: []) == 0...1)
    }
}
