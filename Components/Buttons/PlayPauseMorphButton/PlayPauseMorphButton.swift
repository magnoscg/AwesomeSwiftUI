// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A triangle that morphs into two bars as `progress` goes from 0 to 1.
struct PlayPauseMorphButtonShape: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    /// The triangle, cut in two, in a unit square. Corners match one to one with `pauseBars`.
    private static let playHalves: [[CGPoint]] = [
        [CGPoint(x: 0.22, y: 0.1), CGPoint(x: 0.57, y: 0.3), CGPoint(x: 0.57, y: 0.7), CGPoint(x: 0.22, y: 0.9)],
        [CGPoint(x: 0.57, y: 0.3), CGPoint(x: 0.92, y: 0.5), CGPoint(x: 0.92, y: 0.5), CGPoint(x: 0.57, y: 0.7)],
    ]

    private static let pauseBars: [[CGPoint]] = [
        [CGPoint(x: 0.2, y: 0.1), CGPoint(x: 0.42, y: 0.1), CGPoint(x: 0.42, y: 0.9), CGPoint(x: 0.2, y: 0.9)],
        [CGPoint(x: 0.58, y: 0.1), CGPoint(x: 0.8, y: 0.1), CGPoint(x: 0.8, y: 0.9), CGPoint(x: 0.58, y: 0.9)],
    ]

    /// The two four-cornered pieces at the current progress, in a unit square.
    func pieces() -> [[CGPoint]] {
        let amount = min(max(progress, 0), 1)
        return zip(Self.playHalves, Self.pauseBars).map { play, pause in
            zip(play, pause).map { from, to in
                CGPoint(x: from.x + (to.x - from.x) * amount, y: from.y + (to.y - from.y) * amount)
            }
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for piece in pieces() {
            path.addLines(piece.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) })
            path.closeSubpath()
        }
        return path
    }
}

/// A play button whose triangle morphs into two pause bars.
///
/// With Reduce Motion on, the icon changes without morphing.
struct PlayPauseMorphButton: View {
    @Binding var isPlaying: Bool
    var colors: [Color] = [.pink, .purple]

    @ScaledMetric(relativeTo: .largeTitle) private var size = 92.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            withAnimation(reduceMotion ? nil : .spring(duration: 0.42, bounce: 0.2)) { isPlaying.toggle() }
        } label: {
            let shape = PlayPauseMorphButtonShape(progress: isPlaying ? 1 : 0)

            ZStack {
                shape.fill(.white)
                // A stroke of the same color softens the corners.
                shape.stroke(.white, style: StrokeStyle(lineWidth: size * 0.04, lineJoin: .round))
            }
            .frame(width: size * 0.42, height: size * 0.42)
            .frame(width: size, height: size)
            .background(.linearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
            .shadow(color: (colors.first ?? .black).opacity(0.4), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? "Pause" : "Play")
    }
}

// MARK: - Demo

struct PlayPauseMorphButtonDemo: View {
    @State private var isPlaying = false

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 6) {
                Text("Midnight Drive")
                    .font(.system(.title, design: .rounded, weight: .bold))
                Text(isPlaying ? "Now playing" : "Paused")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            PlayPauseMorphButton(isPlaying: $isPlaying)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    PlayPauseMorphButtonDemo()
}
