// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A card that leans in 3D toward the finger, with a highlight that follows it.
///
/// `restingPoint` is where the card leans while nobody touches it. `nil` keeps it flat.
/// With Reduce Motion on, the card stays flat and only the highlight moves.
struct TiltCard<Content: View>: View {
    var maxAngle: Double = 14
    var cornerRadius: CGFloat = 28
    var restingPoint: UnitPoint?
    @ViewBuilder var content: () -> Content

    @GestureState private var touchPoint: UnitPoint?
    @State private var size = CGSize.zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection

    private var focus: UnitPoint? { touchPoint ?? restingPoint }

    private var pitch: Double {
        guard let focus, !reduceMotion else { return 0 }
        return (0.5 - focus.y) * 2 * maxAngle
    }

    private var yaw: Double {
        guard let focus, !reduceMotion else { return 0 }
        return (focus.x - 0.5) * 2 * maxAngle
    }

    var body: some View {
        content()
            .overlay { highlight }
            .clipShape(.rect(cornerRadius: cornerRadius))
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
            .gesture(tilt)
            .shadow(color: .black.opacity(0.35), radius: 24, y: 16)
            .rotation3DEffect(.degrees(pitch), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
            .rotation3DEffect(.degrees(yaw), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3), value: touchPoint)
    }

    private var highlight: some View {
        RadialGradient(
            colors: [.white.opacity(0.35), .white.opacity(0)],
            center: focus ?? .center,
            startRadius: 0,
            endRadius: max(size.width, size.height) * 0.8
        )
        .blendMode(.plusLighter)
        .opacity(focus == nil ? 0 : 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var tilt: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($touchPoint) { value, state, _ in
                guard size.width > 0, size.height > 0 else { return }
                // Gestures report screen points, but a unit point counts from the leading edge.
                let x = min(max(value.location.x / size.width, 0), 1)
                state = UnitPoint(
                    x: layoutDirection == .rightToLeft ? 1 - x : x,
                    y: min(max(value.location.y / size.height, 0), 1)
                )
            }
    }
}

// MARK: - Demo

struct TiltCardDemo: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .indigo], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion)) { context in
                let time = context.date.timeIntervalSinceReferenceDate * 1.6

                TiltCard(restingPoint: reduceMotion ? nil : UnitPoint(x: 0.5 + 0.45 * cos(time), y: 0.5 + 0.45 * sin(time))) {
                    card
                }
            }
            .padding(.horizontal, 44)
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .accessibilityHidden(true)

            Spacer()

            Text("Aurora Pass")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("Touch and move your finger")
                .font(.subheadline)
                .opacity(0.8)
        }
        .foregroundStyle(.white)
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .aspectRatio(0.68, contentMode: .fit)
        .background(LinearGradient(colors: [.purple, .pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    TiltCardDemo()
}
