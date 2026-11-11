// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A slowly moving aurora built with a mesh gradient.
///
/// With Reduce Motion on, it shows a still gradient.
struct AuroraMeshBackground: View {
    var first: Color = .indigo
    var second: Color = .purple
    var third: Color = .teal
    var speed: Double = 0.6

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            MeshGradient(
                width: AuroraMesh.size,
                height: AuroraMesh.size,
                points: AuroraMesh.points(at: reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate * speed),
                colors: [
                    first, second, first,
                    third, second, first,
                    second, first, third,
                ]
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

enum AuroraMesh {
    static let size = 3

    /// Corners stay fixed and edge points slide along their edge, so the mesh always fills the view.
    static func points(at time: TimeInterval) -> [SIMD2<Float>] {
        func wave(speed: Double, phase: Double) -> Double {
            0.5 + sin(time * speed + phase) * 0.2
        }

        let positions: [(Double, Double)] = [
            (0, 0), (wave(speed: 0.8, phase: 2.1), 0), (1, 0),
            (0, wave(speed: 0.9, phase: 0)), (wave(speed: 1, phase: 0.7), wave(speed: 0.6, phase: 4.2)), (1, wave(speed: 0.7, phase: 1.3)),
            (0, 1), (wave(speed: 1.1, phase: 3.4), 1), (1, 1),
        ]
        return positions.map { SIMD2(Float($0.0), Float($0.1)) }
    }
}

// MARK: - Demo

struct AuroraMeshBackgroundDemo: View {
    var body: some View {
        ZStack {
            AuroraMeshBackground()

            Text("Aurora")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    AuroraMeshBackgroundDemo()
}
