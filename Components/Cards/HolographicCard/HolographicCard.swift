// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

nonisolated enum HolographicCardMath {
    /// How far the card leans for a drag, from -1 to 1 on each axis.
    /// Dragging half the card's size leans it all the way.
    static func tilt(for translation: CGSize, in size: CGSize) -> CGSize {
        guard size.width > 0, size.height > 0 else { return .zero }
        return CGSize(
            width: min(max(translation.width / (size.width / 2), -1), 1),
            height: min(max(translation.height / (size.height / 2), -1), 1)
        )
    }

    /// The degrees the card turns around its vertical axis for a lean from -1 to 1.
    /// `rotation3DEffect` mirrors in a right-to-left layout and a drag does not, so the turn is reversed there.
    static func yaw(for lean: Double, maxAngle: Double, layoutDirection: LayoutDirection) -> Double {
        let turn = lean * maxAngle
        return layoutDirection == .rightToLeft ? -turn : turn
    }

    /// The function in `HolographicCard.metal`, with its arguments in the order it declares them.
    static func shader(size: CGSize, tilt: CGSize, intensity: Double) -> Shader {
        ShaderLibrary.HolographicCardFoil(.float2(size), .float2(tilt), .float(intensity))
    }
}

/// A card with a holographic foil that shifts as you tilt it by dragging, drawn by a Metal shader.
///
/// Copy two files into the same target: `HolographicCard.swift` and `HolographicCard.metal`.
/// A shader draws what SwiftUI draws itself: a view backed by UIKit, such as a map, shows a placeholder.
///
/// With Reduce Motion on, the card stays flat and the foil stays still.
struct HolographicCard<Content: View>: View {
    /// The degrees the card leans at the end of a drag.
    var maxAngle: Double = 16
    var cornerRadius: CGFloat = 28
    /// How much foil the card has, from 0 for none to 1.
    var intensity: Double = 1
    @ViewBuilder var content: () -> Content

    @GestureState private var tilt = CGSize.zero
    @State private var size = CGSize.zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content()
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
            .modifier(
                HolographicCardSurface(
                    tilt: reduceMotion ? .zero : tilt,
                    size: size,
                    maxAngle: maxAngle,
                    cornerRadius: cornerRadius,
                    intensity: intensity
                )
            )
            .gesture(drag)
            .animation(.spring(duration: 0.5, bounce: 0.3), value: tilt)
    }

    private var drag: some Gesture {
        DragGesture(coordinateSpace: .global)
            .updating($tilt) { value, tilt, _ in
                tilt = HolographicCardMath.tilt(for: value.translation, in: size)
            }
    }
}

/// `Animatable`, so the foil follows the same spring as the lean: a shader's arguments do not animate by themselves.
private struct HolographicCardSurface: ViewModifier, Animatable {
    var tilt: CGSize
    let size: CGSize
    let maxAngle: Double
    let cornerRadius: CGFloat
    let intensity: Double

    @Environment(\.layoutDirection) private var layoutDirection

    nonisolated var animatableData: CGSize.AnimatableData {
        get { tilt.animatableData }
        set { tilt.animatableData = newValue }
    }

    func body(content: Content) -> some View {
        content
            .colorEffect(HolographicCardMath.shader(size: size, tilt: tilt, intensity: intensity))
            .clipShape(.rect(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.4), radius: 24, y: 16)
            .rotation3DEffect(.degrees(-tilt.height * maxAngle), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
            .rotation3DEffect(
                .degrees(HolographicCardMath.yaw(for: tilt.width, maxAngle: maxAngle, layoutDirection: layoutDirection)),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.6
            )
    }
}

// MARK: - Demo

struct HolographicCardDemo: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.04, blue: 0.09), Color(red: 0.14, green: 0.09, blue: 0.27)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            HolographicCard {
                card
            }
            .padding(.horizontal, 44)
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title)
                    .accessibilityHidden(true)

                Spacer()

                Text("No. 001")
                    .font(.footnote.monospaced())
                    .opacity(0.7)
            }

            Spacer()

            Text("Prism Pass")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("Drag to tilt the card")
                .font(.subheadline)
                .opacity(0.8)
        }
        .foregroundStyle(.white)
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .aspectRatio(0.68, contentMode: .fit)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.12, blue: 0.3),
                    Color(red: 0.32, green: 0.12, blue: 0.42),
                    Color(red: 0.06, green: 0.06, blue: 0.14),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HolographicCardDemo()
}
