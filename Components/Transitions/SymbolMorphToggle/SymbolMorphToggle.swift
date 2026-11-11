// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A toggle whose SF Symbol morphs between two states with the magic replace effect.
/// The magic effect shows between related symbols, such as `bell.fill` and `bell.slash.fill`.
///
/// With Reduce Motion on, the symbols fade.
struct SymbolMorphToggle: View {
    let title: LocalizedStringResource
    let onSymbol: String
    let offSymbol: String
    @Binding var isOn: Bool
    var tint: Color = .blue

    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize = 44.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var transition: ContentTransition {
        reduceMotion ? .opacity : .symbolEffect(.replace.magic(fallback: .downUp.byLayer))
    }

    var body: some View {
        Button {
            withAnimation(.smooth(duration: 0.4)) { isOn.toggle() }
        } label: {
            VStack(spacing: 12) {
                Image(systemName: isOn ? onSymbol : offSymbol)
                    .font(.system(size: symbolSize, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .contentTransition(transition)
                    .frame(height: symbolSize * 1.3)
                    .foregroundStyle(isOn ? tint : .secondary)

                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 24))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAddTraits(.isToggle)
    }
}

// MARK: - Demo

struct SymbolMorphToggleDemo: View {
    @State private var alerts = true
    @State private var microphone = true
    @State private var camera = true
    @State private var network = true

    var body: some View {
        Grid(horizontalSpacing: 14, verticalSpacing: 14) {
            GridRow {
                SymbolMorphToggle(title: "Alerts", onSymbol: "bell.fill", offSymbol: "bell.slash.fill", isOn: $alerts, tint: .orange)
                SymbolMorphToggle(title: "Microphone", onSymbol: "mic.fill", offSymbol: "mic.slash.fill", isOn: $microphone, tint: .pink)
            }

            GridRow {
                SymbolMorphToggle(title: "Camera", onSymbol: "video.fill", offSymbol: "video.slash.fill", isOn: $camera, tint: .green)
                SymbolMorphToggle(title: "Network", onSymbol: "wifi", offSymbol: "wifi.slash", isOn: $network, tint: .blue)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

#Preview {
    SymbolMorphToggleDemo()
}
