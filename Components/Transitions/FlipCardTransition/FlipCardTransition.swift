// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A two-sided card that flips with a 3D rotation when `isFlipped` changes.
///
/// With Reduce Motion on, the faces swap without rotating.
struct FlipCardTransition<Front: View, Back: View>: View {
    let isFlipped: Bool
    @ViewBuilder var front: () -> Front
    @ViewBuilder var back: () -> Back

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        FlipCardFaces(degrees: isFlipped ? 180 : 0, front: front(), back: back())
            .animation(reduceMotion ? nil : .smooth(duration: 0.7), value: isFlipped)
    }
}

// Animatable so the visible face is chosen from the angle on every frame, at the exact
// moment the card is edge-on. A Bool would show a mirrored face for half of the flip.
private struct FlipCardFaces<Front: View, Back: View>: View, Animatable {
    nonisolated var degrees: Double
    let front: Front
    let back: Back

    nonisolated var animatableData: Double {
        get { degrees }
        set { degrees = newValue }
    }

    private var showsFront: Bool { degrees < 90 }

    var body: some View {
        ZStack {
            front
                .opacity(showsFront ? 1 : 0)
                .accessibilityHidden(!showsFront)

            // Turned half way so it reads correctly once the card has turned the other half.
            back
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(showsFront ? 0 : 1)
                .accessibilityHidden(showsFront)
        }
        .rotation3DEffect(.degrees(degrees), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
    }
}

// MARK: - Demo

struct FlipCardTransitionDemo: View {
    @State private var isFlipped = false
    @ScaledMetric(relativeTo: .title) private var cardHeight = 240.0

    var body: some View {
        VStack(spacing: 40) {
            FlipCardTransition(isFlipped: isFlipped) {
                face(colors: [.indigo, .purple]) {
                    Image(systemName: "creditcard.fill")
                        .font(.largeTitle)
                        .accessibilityHidden(true)
                    Text("Membership")
                        .font(.title.bold())
                    Text("Tap Flip to see the back")
                        .font(.subheadline)
                }
            } back: {
                face(colors: [.teal, .mint]) {
                    Image(systemName: "qrcode")
                        .font(.largeTitle)
                        .accessibilityHidden(true)
                    Text("No. 2026 0042")
                        .font(.title.monospacedDigit().bold())
                    Text("Valid until December")
                        .font(.subheadline)
                }
            }
            .frame(height: cardHeight)
            .padding(.horizontal, 28)

            Button("Flip", systemImage: "arrow.left.arrow.right") {
                isFlipped.toggle()
            }
            .font(.headline)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private func face(colors: [Color], @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 10) {
            content()
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
            in: .rect(cornerRadius: 28)
        )
    }
}

#Preview {
    FlipCardTransitionDemo()
}
