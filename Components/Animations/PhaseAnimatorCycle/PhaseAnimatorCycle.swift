// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

private enum PhaseAnimatorCyclePhase: CaseIterable {
    case rest, lift, tilt, shrink

    var scale: Double {
        switch self {
        case .rest: 1
        case .lift: 1.14
        case .tilt: 1.04
        case .shrink: 0.88
        }
    }

    var rotation: Angle {
        switch self {
        case .rest: .zero
        case .lift: .degrees(-7)
        case .tilt: .degrees(9)
        case .shrink: .degrees(-3)
        }
    }

    var color: Color {
        switch self {
        case .rest: .indigo
        case .lift: .purple
        case .tilt: .pink
        case .shrink: .orange
        }
    }

    var animation: Animation {
        switch self {
        case .rest, .tilt: .spring(duration: 0.6, bounce: 0.4)
        case .lift, .shrink: .easeInOut(duration: 0.55)
        }
    }
}

/// A card that loops through phases of scale, rotation and color.
///
/// With Reduce Motion on, the card stays in its first phase.
struct PhaseAnimatorCycle<Content: View>: View {
    var cornerRadius: CGFloat = 32
    @ViewBuilder var content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            card(.rest)
        } else {
            PhaseAnimator(PhaseAnimatorCyclePhase.allCases) { phase in
                card(phase)
            } animation: { phase in
                phase.animation
            }
        }
    }

    private func card(_ phase: PhaseAnimatorCyclePhase) -> some View {
        content()
            .background {
                RoundedRectangle(cornerRadius: max(0, cornerRadius), style: .continuous)
                    .fill(phase.color)
                    .overlay {
                        RoundedRectangle(cornerRadius: max(0, cornerRadius), style: .continuous)
                            .fill(.linearGradient(colors: [.white.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                    }
                    .shadow(color: phase.color.opacity(0.45), radius: 24, y: 14)
            }
            .scaleEffect(phase.scale)
            .rotationEffect(phase.rotation)
    }
}

// MARK: - Demo

struct PhaseAnimatorCycleDemo: View {
    var body: some View {
        PhaseAnimatorCycle {
            VStack(spacing: 14) {
                Image(systemName: "wand.and.stars")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .accessibilityHidden(true)
                Text("Four phases, one loop")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 56)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    PhaseAnimatorCycleDemo()
}
