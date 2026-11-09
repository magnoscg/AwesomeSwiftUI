// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Testing
@testable import Showcase

struct AuroraMeshBackgroundTests {
    private let times: [Double] = [0, 1.5, 42, 700_000_000]

    @Test func hasOnePointForEachMeshCell() {
        #expect(AuroraMesh.points(at: 3).count == AuroraMesh.size * AuroraMesh.size)
    }

    @Test(arguments: [0, 1.5, 42, 700_000_000.0])
    func cornersStayFixed(time: Double) {
        let points = AuroraMesh.points(at: time)

        #expect(points[0] == SIMD2(0, 0))
        #expect(points[2] == SIMD2(1, 0))
        #expect(points[6] == SIMD2(0, 1))
        #expect(points[8] == SIMD2(1, 1))
    }

    @Test(arguments: [0, 1.5, 42, 700_000_000.0])
    func edgePointsStayOnTheirEdge(time: Double) {
        let points = AuroraMesh.points(at: time)

        #expect(points[1].y == 0)
        #expect(points[3].x == 0)
        #expect(points[5].x == 1)
        #expect(points[7].y == 1)
    }

    @Test func everyPointStaysInsideTheView() {
        for time in times {
            for point in AuroraMesh.points(at: time) {
                #expect((0...1).contains(point.x))
                #expect((0...1).contains(point.y))
            }
        }
    }

    @Test func innerPointsMoveOverTime() {
        #expect(AuroraMesh.points(at: 0)[4] != AuroraMesh.points(at: 1)[4])
    }

    @Test func sameTimeGivesSamePoints() {
        #expect(AuroraMesh.points(at: 7) == AuroraMesh.points(at: 7))
    }
}
