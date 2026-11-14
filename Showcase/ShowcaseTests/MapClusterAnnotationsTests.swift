// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import MapKit
import Testing
@testable import Showcase

struct MapClusterAnnotationsTests {
    private typealias Logic = MapClusterAnnotationsLogic

    private let places = [
        MapClusterAnnotationsPlace(id: "a", name: "A", latitude: 40.41, longitude: -3.70),
        MapClusterAnnotationsPlace(id: "b", name: "B", latitude: 40.42, longitude: -3.69),
        MapClusterAnnotationsPlace(id: "c", name: "C", latitude: 40.95, longitude: -3.10),
    ]

    @Test func placesInTheSameCellBecomeOneGroup() throws {
        let clusters = Logic.clusters(of: places, latitudeDelta: 1.2, longitudeDelta: 1.2)

        #expect(clusters.map { $0.places.map(\.id) } == [["a", "b"], ["c"]])
        let group = try #require(clusters.first)
        #expect(abs(group.latitude - 40.415) < 0.000_001)
        #expect(abs(group.longitude + 3.695) < 0.000_001)
    }

    @Test func zoomingInSplitsAGroup() {
        let clusters = Logic.clusters(of: places, latitudeDelta: 0.03, longitudeDelta: 0.03)

        #expect(clusters.map { $0.places.map(\.id) } == [["a"], ["b"], ["c"]])
    }

    @Test func aGroupIsNamedAfterItsPlaces() {
        let clusters = Logic.clusters(of: places, latitudeDelta: 1.2, longitudeDelta: 1.2)

        #expect(clusters.map(\.id) == ["a|b", "c"])
    }

    @Test func aSpanThatMakesNoSenseLeavesEveryPlaceAlone() {
        #expect(Logic.clusters(of: places, latitudeDelta: 0, longitudeDelta: 1).count == 3)
        #expect(Logic.clusters(of: places, latitudeDelta: .nan, longitudeDelta: 1).count == 3)
    }

    @Test func noPlacesGiveNoGroups() {
        #expect(Logic.clusters(of: [], latitudeDelta: 1, longitudeDelta: 1).isEmpty)
        #expect(Logic.region(fitting: []) == nil)
    }

    @Test func theRegionOfAGroupHoldsItsPlacesWithRoom() throws {
        let region = try #require(Logic.region(fitting: Array(places.prefix(2)), room: 2))

        #expect(abs(region.center.latitude - 40.415) < 0.000_001)
        #expect(abs(region.span.latitudeDelta - 0.02) < 0.000_001)
        #expect(abs(region.span.longitudeDelta - 0.02) < 0.000_001)
    }

    @Test func onePlaceDoesNotZoomAllTheWayIn() throws {
        let region = try #require(Logic.region(fitting: [places[0]]))

        #expect(region.span.latitudeDelta == 0.004)
    }
}
