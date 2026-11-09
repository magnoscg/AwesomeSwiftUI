// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI
import Testing
@testable import Showcase

struct CircleRevealTransitionTests {
    @Test func centeredOriginReachesTheCorners() {
        let radius = CircleRevealTransitionGeometry.coverRadius(from: .center, in: CGSize(width: 6, height: 8))

        #expect(radius == 5)
    }

    @Test func cornerOriginSpansTheDiagonal() {
        let radius = CircleRevealTransitionGeometry.coverRadius(from: .topLeading, in: CGSize(width: 30, height: 40))

        #expect(radius == 50)
    }

    @Test func offCenterOriginUsesTheFarthestCorner() {
        let origin = UnitPoint(x: 0.25, y: 0.5)

        let radius = CircleRevealTransitionGeometry.coverRadius(from: origin, in: CGSize(width: 40, height: 60))

        #expect(radius == hypot(30, 30))
    }

    @Test func emptySizeHasNoRadius() {
        #expect(CircleRevealTransitionGeometry.coverRadius(from: .center, in: .zero) == 0)
    }

    @Test(arguments: [UnitPoint.center, .topLeading, .bottomTrailing, UnitPoint(x: 0.1, y: 0.9)])
    func everyCornerIsCovered(origin: UnitPoint) {
        let size = CGSize(width: 402, height: 874)
        let center = CGPoint(x: size.width * origin.x, y: size.height * origin.y)
        let radius = CircleRevealTransitionGeometry.coverRadius(from: origin, in: size)

        for corner in [CGPoint.zero, CGPoint(x: size.width, y: 0), CGPoint(x: 0, y: size.height), CGPoint(x: size.width, y: size.height)] {
            #expect(hypot(corner.x - center.x, corner.y - center.y) <= radius + 0.001)
        }
    }
}
