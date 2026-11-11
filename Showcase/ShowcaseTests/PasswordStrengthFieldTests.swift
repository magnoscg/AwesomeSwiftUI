// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct PasswordStrengthFieldTests {
    private let rules = PasswordStrengthFieldRule.defaults

    @Test func emptyPasswordHasNoStrength() {
        #expect(PasswordStrengthFieldMeter.level(for: "", rules: rules) == 0)
    }

    @Test func noRulesHasNoStrength() {
        #expect(PasswordStrengthFieldMeter.level(for: "abc", rules: []) == 0)
    }

    @Test func aPasswordThatMeetsNoRuleIsStillWeakNotEmpty() {
        #expect(PasswordStrengthFieldMeter.level(for: "abc", rules: rules) == 1)
    }

    @Test(arguments: [("12345678", 2), ("aB3!", 3), ("sunSET2026!x", 4)])
    func levelFollowsTheRulesMet(password: String, expected: Int) {
        #expect(PasswordStrengthFieldMeter.level(for: password, rules: rules) == expected)
    }
}
