// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI
import Testing
@testable import Showcase

struct PolygonMorphShapeTests {
    @Test func everyFormHasTheSameNumberOfSamples() {
        for form in PolygonMorphShapeForm.allCases {
            #expect(form.radii.values.count == PolygonMorphShapeForm.sampleCount)
        }
    }

    @Test func squareCornersReachTheEdge() {
        #expect(abs(PolygonMorphShapeForm.square.radius(atDegrees: 45) - 1) < 0.001)
        #expect(abs(PolygonMorphShapeForm.square.radius(atDegrees: 0) - 0.7071) < 0.001)
    }

    @Test func starAlternatesTipsAndInnerCorners() {
        #expect(abs(PolygonMorphShapeForm.star.radius(atDegrees: 0) - 1) < 0.001)
        #expect(abs(PolygonMorphShapeForm.star.radius(atDegrees: 36) - 0.46) < 0.001)
        #expect(abs(PolygonMorphShapeForm.star.radius(atDegrees: 72) - 1) < 0.001)
    }

    @Test func starHandlesNegativeAngles() {
        #expect(abs(PolygonMorphShapeForm.star.radius(atDegrees: -36) - 0.46) < 0.001)
    }

    @Test func addingZeroKeepsTheValues() {
        let radii = PolygonMorphShapeRadii(values: [1, 2])

        #expect((radii + .zero).values == [1, 2])
        #expect((PolygonMorphShapeRadii.zero - radii).values == [-1, -2])
    }

    @Test func scalingAndMagnitudeWorkPerValue() {
        var radii = PolygonMorphShapeRadii(values: [3, 4])

        radii.scale(by: 2)

        #expect(radii.values == [6, 8])
        #expect(radii.magnitudeSquared == 100)
    }

    @Test func anEmptyRectangleHasAnEmptyPath() {
        #expect(PolygonMorphShape(form: .star).path(in: .zero).isEmpty)
    }
}
