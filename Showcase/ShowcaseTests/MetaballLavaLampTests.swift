// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import CoreGraphics
import Testing
@testable import Showcase

struct MetaballLavaLampTests {
    private let size = CGSize(width: 402, height: 874)

    @Test(arguments: [CGSize.zero, CGSize(width: -1, height: 200), CGSize(width: 200, height: 0)])
    func anEmptyViewHasNoBlobs(size: CGSize) {
        #expect(MetaballLavaLampMath.blobs(count: 5, time: 1, size: size).isEmpty)
    }

    @Test(arguments: [0, -3])
    func withNoBlobsOnlyThePoolsRemain(count: Int) {
        #expect(MetaballLavaLampMath.blobs(count: count, time: 1, size: size).count == 2)
    }

    @Test func aHugeCountIsCapped() {
        #expect(MetaballLavaLampMath.blobs(count: Int.max, time: 1, size: size).count == 50)
    }

    @Test(arguments: [0.0, 3.7, 91.2, 800_000_000.0])
    func blobCentersStayInsideTheView(time: Double) {
        let blobs = MetaballLavaLampMath.blobs(count: 12, time: time, size: size).dropFirst(2)

        #expect(blobs.count == 12)
        #expect(blobs.allSatisfy { $0.midX >= 0 && $0.midX <= size.width })
        #expect(blobs.allSatisfy { $0.midY >= 0 && $0.midY <= size.height })
        #expect(blobs.allSatisfy { $0.width > 0 && $0.width == $0.height })
    }

    @Test func blobsMoveOverTime() {
        let early = MetaballLavaLampMath.blobs(count: 4, time: 1, size: size)
        let later = MetaballLavaLampMath.blobs(count: 4, time: 2, size: size)

        #expect(early != later)
    }
}
