// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct MapRouteTrackerTests {
    /// Three points on the equator, one degree apart, so every part is as long as the others.
    private let route = [
        MapRouteTrackerPoint(latitude: 0, longitude: 0),
        MapRouteTrackerPoint(latitude: 0, longitude: 1),
        MapRouteTrackerPoint(latitude: 0, longitude: 2),
    ]

    @Test func aDegreeOnTheEquatorIsAbout111Kilometers() {
        let meters = MapRouteTrackerMath.distance(from: route[0], to: route[1])

        #expect(abs(meters - 111_195) < 10)
    }

    @Test func aPointIsNoDistanceFromItself() {
        #expect(MapRouteTrackerMath.distance(from: route[1], to: route[1]) == 0)
    }

    @Test func distancesAddUpAlongTheRoute() {
        let distances = MapRouteTrackerMath.distances(along: route)

        #expect(distances.count == 3)
        #expect(distances[0] == 0)
        #expect(abs(distances[2] - distances[1] * 2) < 0.001)
    }

    @Test func theRouteStartsAndEndsAtItsEnds() {
        #expect(MapRouteTrackerMath.point(at: 0, on: route) == route[0])
        #expect(MapRouteTrackerMath.point(at: 1, on: route) == route[2])
    }

    @Test func halfwayIsTheMiddlePoint() throws {
        let middle = try #require(MapRouteTrackerMath.point(at: 0.5, on: route))

        #expect(abs(middle.longitude - 1) < 0.000_001)
        #expect(middle.latitude == 0)
    }

    @Test func aQuarterOfTheWayIsInsideTheFirstPart() throws {
        let point = try #require(MapRouteTrackerMath.point(at: 0.25, on: route))

        #expect(abs(point.longitude - 0.5) < 0.000_001)
    }

    @Test func progressOutsideItsRangeIsClamped() {
        #expect(MapRouteTrackerMath.point(at: -3, on: route) == route[0])
        #expect(MapRouteTrackerMath.point(at: 8, on: route) == route[2])
        #expect(MapRouteTrackerMath.point(at: .nan, on: route) == route[0])
    }

    @Test func theCutPointIsInBothHalves() throws {
        let parts = MapRouteTrackerMath.split(route, at: 0.75)
        let cut = try #require(parts.done.last)

        #expect(parts.left.first == cut)
        #expect(parts.done.count == 3)
        #expect(parts.left.count == 2)
        #expect(abs(cut.longitude - 1.5) < 0.000_001)
    }

    @Test func atTheStartEverythingIsLeft() {
        let parts = MapRouteTrackerMath.split(route, at: 0)

        #expect(parts.done.last == route[0])
        #expect(parts.left.last == route[2])
        #expect(parts.left.count == 3)
    }

    @Test func aRouteOfOnePointStaysThere() {
        let parts = MapRouteTrackerMath.split([route[0]], at: 0.6)

        #expect(parts.done == [route[0]])
        #expect(parts.left == [route[0]])
    }

    @Test func anEmptyRouteHasNoPoint() {
        #expect(MapRouteTrackerMath.point(at: 0.5, on: []) == nil)
        #expect(MapRouteTrackerMath.distances(along: []).isEmpty)
    }

    @Test func repeatedPointsDoNotBreakTheCut() {
        let route = [route[0], route[0], route[1]]

        #expect(MapRouteTrackerMath.point(at: 0, on: route) == route[0])
        #expect(MapRouteTrackerMath.point(at: 1, on: route) == route[2])
    }
}
