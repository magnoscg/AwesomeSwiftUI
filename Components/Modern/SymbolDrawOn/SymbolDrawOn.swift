// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// An SF Symbol that draws itself on and off, stroke by stroke.
///
/// Only symbols with Draw annotations trace their strokes. Others fall back to a simpler
/// appearance. With Reduce Motion on, the symbol fades.
@available(iOS 26, *)
struct SymbolDrawOn: View {
    let systemName: String
    var isDrawn: Bool
    var label: LocalizedStringKey?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image(systemName: systemName)
            .symbolEffect(.drawOn.byLayer, isActive: !isDrawn)
            .symbolEffect(.drawOff.byLayer, isActive: !isDrawn)
            .symbolEffectsRemoved(reduceMotion)
            .opacity(reduceMotion && !isDrawn ? 0 : 1)
            .accessibilityHidden(label == nil)
            .accessibilityLabel(label ?? "")
    }
}

// MARK: - Demo

@available(iOS 26, *)
struct SymbolDrawOnDemo: View {
    @State private var isDrawn = true
    @ScaledMetric(relativeTo: .largeTitle) private var cellSize = 104.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let symbols = ["signature", "scribble", "wind", "sun.max", "cloud.rain", "checkmark.circle"]

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            LazyVGrid(columns: [GridItem(.adaptive(minimum: cellSize))], spacing: 28) {
                ForEach(symbols, id: \.self) { symbol in
                    SymbolDrawOn(systemName: symbol, isDrawn: isDrawn)
                        .font(.largeTitle.weight(.medium))
                        .imageScale(.large)
                        .foregroundStyle(.white)
                        .frame(height: cellSize)
                }
            }
            .padding(24)
        }
        .task {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(isDrawn ? 1.8 : 1.3))
                withAnimation { isDrawn.toggle() }
            }
        }
    }
}

@available(iOS 26, *)
#Preview {
    SymbolDrawOnDemo()
}
