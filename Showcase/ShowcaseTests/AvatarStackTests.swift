// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct AvatarStackTests {
    @Test func everyoneFitsWithoutABadge() {
        let split = AvatarStackMath.visibleAndOverflow(count: 3, maxVisible: 4)

        #expect(split.visible == 3)
        #expect(split.overflow == 0)
    }

    @Test func exactlyTheLimitHasNoOverflow() {
        let split = AvatarStackMath.visibleAndOverflow(count: 4, maxVisible: 4)

        #expect(split.visible == 4)
        #expect(split.overflow == 0)
    }

    @Test func theRestGoIntoTheBadge() {
        let split = AvatarStackMath.visibleAndOverflow(count: 9, maxVisible: 4)

        #expect(split.visible == 4)
        #expect(split.overflow == 5)
    }

    @Test func negativeInputsAreTreatedAsZero() {
        let noRoom = AvatarStackMath.visibleAndOverflow(count: 3, maxVisible: -1)
        let nobody = AvatarStackMath.visibleAndOverflow(count: -2, maxVisible: 4)

        #expect(noRoom.visible == 0)
        #expect(noRoom.overflow == 3)
        #expect(nobody.visible == 0)
        #expect(nobody.overflow == 0)
    }

    @Test(arguments: [
        ("Ana Ruiz", "AR"),
        ("ana maría ruiz", "AR"),
        ("Plato", "P"),
        ("  Óscar   Cantón ", "ÓC"),
        ("", "?"),
        ("   ", "?"),
    ])
    func initials(name: String, expected: String) {
        #expect(AvatarStackMath.initials(of: name) == expected)
    }
}
