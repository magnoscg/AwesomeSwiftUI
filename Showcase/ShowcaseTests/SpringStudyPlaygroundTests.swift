// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct SpringStudyPlaygroundTests {
    @Test func startsAtZeroAndSettlesOnTheTarget() throws {
        let samples = SpringStudyPlaygroundMath.samples(response: 0.3, damping: 1, count: 60, duration: 3)
        let first = try #require(samples.first)
        let last = try #require(samples.last)

        #expect(abs(first) < 0.001)
        #expect(abs(last - 1) < 0.01)
    }

    @Test func lowDampingOvershoots() throws {
        let samples = SpringStudyPlaygroundMath.samples(response: 0.6, damping: 0.2, count: 120, duration: 2)
        let peak = try #require(samples.max())

        #expect(peak > 1.2)
    }

    @Test(arguments: [(0, 2.0), (1, 2.0), (10, 0.0), (10, -1.0), (10, Double.infinity)] as [(Int, Double)])
    func invalidSamplingGivesNothing(count: Int, duration: Double) {
        #expect(SpringStudyPlaygroundMath.samples(response: 0.5, damping: 0.5, count: count, duration: duration).isEmpty)
    }

    @Test func hostileSpringValuesAreClamped() {
        let samples = SpringStudyPlaygroundMath.samples(response: 0, damping: -4, count: 8, duration: 1)

        #expect(samples.count == 8)
        #expect(samples.allSatisfy { $0.isFinite })
    }

    @Test func notANumberClampsToTheLowerBound() {
        #expect(SpringStudyPlaygroundMath.clamped(.nan, to: 0.1...1) == 0.1)
    }
}
