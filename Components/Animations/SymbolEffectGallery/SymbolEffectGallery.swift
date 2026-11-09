// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

private enum SymbolEffectGalleryEffect: String, CaseIterable, Identifiable {
    case bounce = "Bounce"
    case pulse = "Pulse"
    case variableColor = "Variable Color"
    case wiggle = "Wiggle"
    case rotate = "Rotate"
    case breathe = "Breathe"

    var id: Self { self }

    var symbol: String {
        switch self {
        case .bounce: "arrow.down.circle.fill"
        case .pulse: "heart.fill"
        case .variableColor: "wifi"
        case .wiggle: "bell.fill"
        case .rotate: "gearshape.2.fill"
        case .breathe: "moon.stars.fill"
        }
    }

    var color: Color {
        switch self {
        case .bounce: .blue
        case .pulse: .pink
        case .variableColor: .teal
        case .wiggle: .orange
        case .rotate: .indigo
        case .breathe: .purple
        }
    }
}

/// A gallery of SF Symbol effects. Tapping a tile plays its effect once.
///
/// With Reduce Motion on, the effects are removed and the symbols stay still.
struct SymbolEffectGallery: View {
    @ScaledMetric(relativeTo: .body) private var minimumColumn = 150.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumColumn), spacing: 14)], spacing: 14) {
                ForEach(SymbolEffectGalleryEffect.allCases) { effect in
                    SymbolEffectGalleryTile(effect: effect)
                }
            }
            .padding(20)
        }
        .symbolEffectsRemoved(reduceMotion)
    }
}

private struct SymbolEffectGalleryTile: View {
    let effect: SymbolEffectGalleryEffect

    @State private var plays = 0
    @ScaledMetric(relativeTo: .largeTitle) private var height = 68.0

    var body: some View {
        Button {
            plays += 1
        } label: {
            VStack(spacing: 14) {
                symbol
                    .font(.largeTitle)
                    .foregroundStyle(effect.color)
                    .frame(height: height)

                Text(effect.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .padding(.horizontal, 12)
            .background(effect.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(effect.rawValue)
        .accessibilityHint("Plays the effect")
    }

    @ViewBuilder private var symbol: some View {
        let image = Image(systemName: effect.symbol).accessibilityHidden(true)

        switch effect {
        case .bounce: image.symbolEffect(.bounce, value: plays)
        case .pulse: image.symbolEffect(.pulse, value: plays)
        case .variableColor: image.symbolEffect(.variableColor.iterative, value: plays)
        case .wiggle: image.symbolEffect(.wiggle, value: plays)
        case .rotate: image.symbolEffect(.rotate, value: plays)
        case .breathe: image.symbolEffect(.breathe, value: plays)
        }
    }
}

// MARK: - Demo

struct SymbolEffectGalleryDemo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Symbol Effects")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .padding(.horizontal, 20)
                .padding(.top, 12)

            SymbolEffectGallery()
        }
    }
}

#Preview {
    SymbolEffectGalleryDemo()
}
