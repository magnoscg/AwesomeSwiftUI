// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// Caps its content to a comfortable reading width and centers it on wide screens.
/// The limit grows with Dynamic Type, so lines keep about the same number of words.
struct ReadableWidthContainer<Content: View>: View {
    @ScaledMetric private var maxWidth: CGFloat
    private let content: Content

    init(maxWidth: CGFloat = 640, @ViewBuilder content: () -> Content) {
        _maxWidth = ScaledMetric(wrappedValue: maxWidth.isFinite ? max(0, maxWidth) : 640, relativeTo: .body)
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: maxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Demo

struct ReadableWidthContainerDemo: View {
    @State private var isExpanded = false
    @State private var autoPlays = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var expandedBinding: Binding<Bool> {
        Binding(get: { isExpanded }, set: { newValue in
            autoPlays = false
            isExpanded = newValue
        })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
            Toggle("Wider screen", isOn: expandedBinding)
                .font(.headline)

            ReadableWidthContainer(maxWidth: 240) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("On reading")
                        .font(.title2.bold())
                    Text("Long lines tire the eye. Past a certain width the text stops growing and simply sits in the middle of the space.")
                        .font(.body)
                }
                .padding(16)
                .background(.indigo.opacity(0.14), in: .rect(cornerRadius: 16, style: .continuous))
            }
            .padding(.vertical, 22)
            .frame(maxWidth: isExpanded ? 362 : 250)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                    .accessibilityHidden(true)
            }

            }
            .padding(20)
        }
        .tint(.indigo)
        .task(id: autoPlays && !reduceMotion) {
            guard autoPlays, !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.3))
                guard !Task.isCancelled else { return }
                withAnimation(.smooth(duration: 0.5)) { isExpanded.toggle() }
            }
        }
    }
}

#Preview {
    ReadableWidthContainerDemo()
}
