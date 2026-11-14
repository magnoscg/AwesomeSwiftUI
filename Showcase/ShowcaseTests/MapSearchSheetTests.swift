// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct MapSearchSheetTests {
    private let places = [
        MapSearchSheetPlace(id: "coffee", name: "Harbor Coffee", kind: "Café", symbol: "cup.and.saucer.fill", latitude: 38.71, longitude: -9.14),
        MapSearchSheetPlace(id: "books", name: "Old Town Books", kind: "Bookshop", symbol: "book.fill", latitude: 38.71, longitude: -9.13),
        MapSearchSheetPlace(id: "museum", name: "Tile Museum Café", kind: "Café", symbol: "cup.and.saucer.fill", latitude: 38.72, longitude: -9.13),
    ]

    private func ids(_ query: String) -> [String] {
        MapSearchSheetLogic.matches(places, query: query).map(\.id)
    }

    @Test func anEmptyQueryKeepsEveryPlace() {
        #expect(ids("") == ["coffee", "books", "museum"])
        #expect(ids("   ") == ["coffee", "books", "museum"])
    }

    @Test func theNameIsSearchedWhateverItsCase() {
        #expect(ids("harbor") == ["coffee"])
        #expect(ids("OLD TOWN") == ["books"])
    }

    @Test func theKindIsSearchedToo() {
        #expect(ids("bookshop") == ["books"])
    }

    @Test func accentsDoNotMatter() {
        #expect(ids("cafe") == ["coffee", "museum"])
        #expect(ids("Café") == ["coffee", "museum"])
    }

    @Test func everyWordHasToBeThere() {
        #expect(ids("museum cafe") == ["museum"])
        #expect(ids("cafe harbor") == ["coffee"])
        #expect(ids("museum books").isEmpty)
    }

    @Test func partOfAWordIsEnough() {
        #expect(ids("boo") == ["books"])
    }

    @Test func nothingMatchesAnUnknownWord() {
        #expect(ids("pharmacy").isEmpty)
    }

    @Test func aPlaceKnowsItsCoordinate() {
        #expect(places[0].coordinate.latitude == 38.71)
        #expect(places[0].coordinate.longitude == -9.14)
    }
}
