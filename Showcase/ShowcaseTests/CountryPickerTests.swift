// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Foundation
import Testing
@testable import Showcase

struct CountryPickerTests {
    private let sample = [
        CountryPickerCountry(code: "ES", name: "España", dialCode: "+34"),
        CountryPickerCountry(code: "FR", name: "France", dialCode: "+33"),
        CountryPickerCountry(code: "US", name: "United States", dialCode: "+1"),
    ]

    @Test func twoLettersMakeAFlag() {
        #expect(CountryPickerData.flag(for: "ES") == "🇪🇸")
        #expect(CountryPickerData.flag(for: "es") == "🇪🇸")
    }

    @Test(arguments: ["", "E", "ESP", "E5", "419"]) func anythingElseHasNoFlag(code: String) {
        #expect(CountryPickerData.flag(for: code).isEmpty)
    }

    @Test func theTableIsParsedAndBadEntriesSkipped() {
        let codes = CountryPickerData.parseDialCodes("ES34 US1 E1 FRxx")

        #expect(codes == ["ES": "+34", "US": "+1"])
    }

    @Test func aRepeatedEntryDoesNotCrash() {
        #expect(CountryPickerData.parseDialCodes("ES34 ES35") == ["ES": "+34"])
    }

    @Test func emptySearchKeepsEveryone() {
        #expect(CountryPickerData.filter(sample, query: "   ") == sample)
    }

    @Test func namesMatchWithoutAccents() {
        #expect(CountryPickerData.filter(sample, query: "espana").map(\.code) == ["ES"])
    }

    @Test(arguments: ["+33", "33"]) func dialCodesMatch(query: String) {
        #expect(CountryPickerData.filter(sample, query: query).map(\.code) == ["FR"])
    }

    @Test func aLonePlusMatchesNoDialCode() {
        #expect(CountryPickerData.filter(sample, query: "+").isEmpty)
    }

    @Test func theListHasOnlyRealCountriesInOrder() throws {
        let countries = CountryPickerData.countries(locale: Locale(identifier: "en_US"))
        let spain = try #require(countries.first { $0.code == "ES" })

        #expect(spain.name == "Spain")
        #expect(spain.dialCode == "+34")
        #expect(countries.allSatisfy { $0.code.count == 2 && !$0.flag.isEmpty })
        #expect(countries.map(\.name) == countries.map(\.name).sorted { $0.localizedStandardCompare($1) == .orderedAscending })
    }
}
