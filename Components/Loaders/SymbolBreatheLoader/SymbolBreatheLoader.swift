// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

enum SymbolBreatheLoaderEffect {
    case breathe
    case rotate
    case both
}

/// An SF Symbol that breathes, rotates or does both while something loads.
///
/// With Reduce Motion on, the symbol stays still.
struct SymbolBreatheLoader: View {
    var systemName: String = "sparkles"
    var effect: SymbolBreatheLoaderEffect = .breathe
    var color: Color = .indigo
    var font: Font = .largeTitle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image(systemName: systemName)
            .font(font)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
            .symbolEffect(.breathe, options: .repeat(.continuous), isActive: !reduceMotion && effect != .rotate)
            .symbolEffect(.rotate, options: .repeat(.continuous), isActive: !reduceMotion && effect != .breathe)
            .accessibilityLabel("Loading")
    }
}

// MARK: - Demo

struct SymbolBreatheLoaderDemo: View {
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize = 130

    var body: some View {
        VStack(spacing: 48) {
            SymbolBreatheLoader(systemName: "sparkles", color: .purple, font: .system(size: heroSize))

            VStack(spacing: 6) {
                Text("Working on it")
                    .font(.system(.title, design: .rounded, weight: .bold))

                Text("Breathe, rotate or both")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 40) {
                SymbolBreatheLoader(systemName: "gearshape.2.fill", effect: .rotate, color: .gray)
                SymbolBreatheLoader(systemName: "arrow.trianglehead.2.clockwise", effect: .rotate, color: .blue)
                SymbolBreatheLoader(systemName: "heart.fill", color: .pink)
                SymbolBreatheLoader(systemName: "fan.fill", effect: .both, color: .teal)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SymbolBreatheLoaderDemo()
}
