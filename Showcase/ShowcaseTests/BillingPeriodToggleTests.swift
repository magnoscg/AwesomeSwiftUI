// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct BillingPeriodToggleTests {
    @Test func savingsRoundToAWholePercent() {
        #expect(BillingPeriodTogglePricing.savingsPercent(monthly: 12, yearly: 99) == 31)
    }

    @Test func aFreeYearSavesEverything() {
        #expect(BillingPeriodTogglePricing.savingsPercent(monthly: 12, yearly: 0) == 100)
    }

    @Test func noSavingShowsNoBadge() {
        #expect(BillingPeriodTogglePricing.savingsPercent(monthly: 12, yearly: 144) == nil)
        #expect(BillingPeriodTogglePricing.savingsPercent(monthly: 12, yearly: 200) == nil)
        #expect(BillingPeriodTogglePricing.savingsPercent(monthly: 12, yearly: 143.99) == nil)
    }

    @Test func invalidPricesShowNoBadge() {
        #expect(BillingPeriodTogglePricing.savingsPercent(monthly: 0, yearly: 10) == nil)
        #expect(BillingPeriodTogglePricing.savingsPercent(monthly: 12, yearly: -1) == nil)
        #expect(BillingPeriodTogglePricing.savingsPercent(monthly: .infinity, yearly: 10) == nil)
        #expect(BillingPeriodTogglePricing.savingsPercent(monthly: .nan, yearly: 10) == nil)
        #expect(BillingPeriodTogglePricing.savingsPercent(monthly: 12, yearly: .nan) == nil)
    }
}
