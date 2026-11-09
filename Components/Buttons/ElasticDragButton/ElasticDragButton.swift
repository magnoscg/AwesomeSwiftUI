// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A round button that stretches toward your finger and springs back on release.
/// A press that does not travel counts as a tap.
///
/// With Reduce Motion on, the button stays in place and only dims while pressed.
struct ElasticDragButton: View {
    let systemImage: String
    let label: String
    var tint: Color = .indigo
    var reach: Double = 80
    let action: () -> Void

    @State private var pull = CGSize.zero
    @State private var stretch = 0.0
    @State private var angle = Angle.zero
    @GestureState private var isPressed = false
    @ScaledMetric(relativeTo: .largeTitle) private var diameter = 112.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let tapTolerance = 12.0

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.gradient)
                .scaleEffect(x: 1 + stretch, y: 1 - stretch * 0.45)
                .rotationEffect(angle)
                .shadow(color: tint.opacity(0.45), radius: 18, y: 10)

            Image(systemName: systemImage)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
        }
        .frame(width: diameter, height: diameter)
        .offset(pull)
        .opacity(isPressed && reduceMotion ? 0.7 : 1)
        .contentShape(.circle)
        .gesture(drag)
        .onChange(of: isPressed) { _, pressed in
            guard !pressed else { return }
            withAnimation(.spring(duration: 0.6, bounce: 0.65)) {
                pull = .zero
                stretch = 0
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { action() }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isPressed) { _, state, _ in state = true }
            .onChanged { value in
                guard !reduceMotion else { return }
                let distance = hypot(value.translation.width, value.translation.height)
                guard distance > 1 else { return }

                let eased = reach * (1 - exp(-distance / (reach * 2)))
                pull = CGSize(
                    width: value.translation.width * eased / distance,
                    height: value.translation.height * eased / distance
                )
                stretch = eased / reach * 0.4
                angle = .radians(atan2(value.translation.height, value.translation.width))
            }
            .onEnded { value in
                if hypot(value.translation.width, value.translation.height) < tapTolerance {
                    action()
                }
            }
    }
}

// MARK: - Demo

struct ElasticDragButtonDemo: View {
    @State private var taps = 0

    var body: some View {
        ElasticDragButton(systemImage: "hand.point.up.left.fill", label: "Stretch") {
            taps += 1
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) {
            VStack(spacing: 6) {
                Text("Pull me")
                    .font(.largeTitle.bold())
                Text(taps == 1 ? "1 tap" : "\(taps) taps")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 72)
        }
        .background(
            LinearGradient(colors: [.indigo.opacity(0.14), .pink.opacity(0.12)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
}

#Preview {
    ElasticDragButtonDemo()
}
