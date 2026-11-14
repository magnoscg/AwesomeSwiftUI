// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import CoreGraphics
import Testing
@testable import Showcase

struct ScratchToRevealTests {
    private let size = CGSize(width: 100, height: 100)

    @Test func startsCovered() {
        #expect(ScratchToRevealCoverage().fraction == 0)
    }

    @Test func aLineClearsCellsBetweenItsEnds() {
        var coverage = ScratchToRevealCoverage(columns: 10, rows: 10)

        coverage.scratch(from: CGPoint(x: 0, y: 50), to: CGPoint(x: 100, y: 50), brushWidth: 10, in: size)

        #expect(coverage.fraction >= 0.1)
        #expect(coverage.fraction <= 0.3)
    }

    @Test func aBrushAsWideAsTheCardClearsEverything() {
        var coverage = ScratchToRevealCoverage(columns: 10, rows: 10)

        coverage.scratch(from: CGPoint(x: 50, y: 50), to: CGPoint(x: 50, y: 50), brushWidth: 300, in: size)

        #expect(coverage.fraction == 1)
    }

    @Test func pointsFarOutsideClearNothing() {
        var coverage = ScratchToRevealCoverage(columns: 10, rows: 10)

        coverage.scratch(from: CGPoint(x: -5000, y: -5000), to: CGPoint(x: -4000, y: -5000), brushWidth: 10, in: size)

        #expect(coverage.fraction == 0)
    }

    @Test(arguments: [CGSize.zero, CGSize(width: -10, height: 40), CGSize(width: 40, height: 0)])
    func emptySizesAreIgnored(size: CGSize) {
        var coverage = ScratchToRevealCoverage()

        coverage.scratch(from: .zero, to: CGPoint(x: 10, y: 10), brushWidth: 10, in: size)

        #expect(coverage.fraction == 0)
    }

    @Test func extremeGridsAreKeptInRange() {
        #expect(ScratchToRevealCoverage(columns: 0, rows: -3).columns == 1)
        #expect(ScratchToRevealCoverage(columns: .max, rows: .max).rows == 256)
    }
}
