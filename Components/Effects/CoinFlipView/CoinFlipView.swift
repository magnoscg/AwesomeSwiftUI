// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

enum CoinFlipViewSide: String, CaseIterable, Hashable {
    case heads = "Heads"
    case tails = "Tails"

    var symbolName: String {
        switch self {
        case .heads: "crown.fill"
        case .tails: "leaf.fill"
        }
    }
}

enum CoinFlipViewMath {
    /// Heads faces the viewer on even half turns.
    static func visibleSide(at angle: Double) -> CoinFlipViewSide {
        cos(angle * .pi / 180) >= 0 ? .heads : .tails
    }

    /// An angle at least `turns` full turns ahead that rests on the landing side.
    static func targetAngle(from angle: Double, landing: CoinFlipViewSide, turns: Int) -> Double {
        let halfTurns = (angle / 180).rounded()
        let target = halfTurns * 180 + Double(min(max(turns, 1), 100)) * 360
        return visibleSide(at: target) == landing ? target : target + 180
    }
}

/// A coin that flips in 3D over several turns and lands on heads or tails. Tap it to flip.
///
/// A tap during a flip is ignored, so each flip reports one result.
/// With Reduce Motion on, the coin shows the result at once.
struct CoinFlipView: View {
    @Binding var side: CoinFlipViewSide
    var size: CGFloat = 180
    var turns: Int = 5
    var onLanded: ((CoinFlipViewSide) -> Void)?

    @State private var angle: Double
    @State private var isFlipping = false
    @State private var flipCount = 0
    @State private var landedCount = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let flipDuration = 1.5

    init(
        side: Binding<CoinFlipViewSide>,
        size: CGFloat = 180,
        turns: Int = 5,
        onLanded: ((CoinFlipViewSide) -> Void)? = nil
    ) {
        _side = side
        self.size = size
        self.turns = turns
        self.onLanded = onLanded
        _angle = State(initialValue: side.wrappedValue == .heads ? 0 : 180)
    }

    private var diameter: CGFloat { max(size, 1) }

    var body: some View {
        Button(action: flip) {
            CoinFlipViewCoin(angle: angle, diameter: diameter)
                .keyframeAnimator(initialValue: 0.0, trigger: flipCount) { [diameter] coin, height in
                    coin.offset(y: -height * diameter * 1.1)
                } keyframes: { _ in
                    CubicKeyframe(1, duration: 0.65)
                    CubicKeyframe(0, duration: 0.85)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Flip coin")
        .accessibilityValue(side.rawValue)
        .sensoryFeedback(.impact(weight: .medium), trigger: landedCount)
        .onChange(of: side) { _, newSide in
            guard !isFlipping, CoinFlipViewMath.visibleSide(at: angle) != newSide else { return }
            angle += 180
        }
    }

    private func flip() {
        guard !isFlipping else { return }

        let landing = CoinFlipViewSide.allCases.randomElement() ?? .heads
        let target = CoinFlipViewMath.targetAngle(from: angle, landing: landing, turns: turns)

        guard !reduceMotion else {
            angle = target
            land(on: landing)
            return
        }

        isFlipping = true
        flipCount += 1
        withAnimation(.timingCurve(0.2, 0.7, 0.3, 1, duration: flipDuration)) {
            angle = target
        } completion: {
            land(on: landing)
        }
    }

    private func land(on landing: CoinFlipViewSide) {
        isFlipping = false
        side = landing
        landedCount += 1
        onLanded?(landing)
    }
}

/// Animatable so its body runs on every frame and can swap the face at the edge-on moment.
private struct CoinFlipViewCoin: View, Animatable {
    var angle: Double
    let diameter: CGFloat

    nonisolated var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        let visible = CoinFlipViewMath.visibleSide(at: angle)

        face(visible)
            .rotation3DEffect(.degrees(visible == .heads ? 0 : 180), axis: (x: 1, y: 0, z: 0))
            .rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0), perspective: 0.4)
    }

    private func face(_ side: CoinFlipViewSide) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1, green: 0.86, blue: 0.45), Color(red: 0.85, green: 0.58, blue: 0.13)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .strokeBorder(.white.opacity(0.5), lineWidth: diameter * 0.03)
                .padding(diameter * 0.07)

            Image(systemName: side.symbolName)
                .font(.system(size: diameter * 0.38, weight: .bold))
                .foregroundStyle(Color(red: 0.55, green: 0.33, blue: 0.05))
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: .black.opacity(0.25), radius: 12, y: 8)
    }
}

// MARK: - Demo

struct CoinFlipViewDemo: View {
    @State private var side = CoinFlipViewSide.heads
    @State private var flips = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Text("Tap the coin")
                    .font(.system(.title, design: .rounded, weight: .bold))

                CoinFlipView(side: $side) { _ in
                    flips += 1
                }
                .padding(.top, 180)

                VStack(spacing: 4) {
                    Text(flips == 0 ? "Ready" : side.rawValue)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))

                    Text("Flips: \(flips)")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .defaultScrollAnchor(.center, for: .alignment)
        .background(
            LinearGradient(colors: [.yellow.opacity(0.18), .orange.opacity(0.12)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
}

#Preview {
    CoinFlipViewDemo()
}
