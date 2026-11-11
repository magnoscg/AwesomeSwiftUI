// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import MapKit
import Testing
@testable import Showcase

struct MapAnnotationCalloutTests {
    @Test func theCameraCentersNorthOfThePin() {
        let center = MapAnnotationCalloutLogic.centerLatitude(showing: 38.7, span: 0.02)

        #expect(abs(center - 38.704) < 0.000_001)
    }

    @Test func aWiderMapShiftsFurther() {
        let near = MapAnnotationCalloutLogic.centerLatitude(showing: 10, span: 0.01)
        let far = MapAnnotationCalloutLogic.centerLatitude(showing: 10, span: 1)

        #expect(far - 10 > near - 10)
    }

    @Test func theShiftCanBeChosen() {
        #expect(MapAnnotationCalloutLogic.centerLatitude(showing: 20, span: 2, shift: 0.5) == 21)
        #expect(MapAnnotationCalloutLogic.centerLatitude(showing: 20, span: 2, shift: 0) == 20)
    }

    @Test func theCenterStaysOnTheGlobe() {
        #expect(MapAnnotationCalloutLogic.centerLatitude(showing: 89.9, span: 10) == 90)
        #expect(MapAnnotationCalloutLogic.centerLatitude(showing: -120, span: 1) == -90)
    }

    @Test func aSpanThatMakesNoSenseDoesNotShift() {
        #expect(MapAnnotationCalloutLogic.centerLatitude(showing: 38.7, span: -3) == 38.7)
        #expect(MapAnnotationCalloutLogic.centerLatitude(showing: 38.7, span: .nan) == 0)
        #expect(MapAnnotationCalloutLogic.centerLatitude(showing: .infinity, span: 1) == 0)
    }

    @Test func anItemKnowsItsCoordinate() {
        let item = MapAnnotationCalloutItem(id: "loft", label: "$120", title: "Rooftop Loft", latitude: 38.71, longitude: -9.14)

        #expect(item.coordinate.latitude == 38.71)
        #expect(item.coordinate.longitude == -9.14)
    }

    @Test func theStartingRegionShowsEveryPinWithRoom() throws {
        let items = [
            MapAnnotationCalloutItem(id: "a", label: "1", title: "A", latitude: 38.70, longitude: -9.16),
            MapAnnotationCalloutItem(id: "b", label: "2", title: "B", latitude: 38.72, longitude: -9.12),
        ]

        let region = try #require(MapAnnotationCalloutLogic.region(fitting: items))

        #expect(abs(region.center.latitude - 38.71) < 0.000_001)
        #expect(abs(region.center.longitude - -9.14) < 0.000_001)
        #expect(abs(region.span.latitudeDelta - 0.032) < 0.000_001)
        #expect(abs(region.span.longitudeDelta - 0.064) < 0.000_001)
    }

    @Test func aSinglePinDoesNotZoomAllTheWayIn() throws {
        let item = MapAnnotationCalloutItem(id: "a", label: "1", title: "A", latitude: 38.7, longitude: -9.1)

        let region = try #require(MapAnnotationCalloutLogic.region(fitting: [item]))

        #expect(region.span.latitudeDelta == 0.01)
        #expect(region.span.longitudeDelta == 0.01)
    }

    @Test func noPinsGiveNoStartingRegion() {
        #expect(MapAnnotationCalloutLogic.region(fitting: []) == nil)
    }
}
