// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A group that lays out its content in a row when there is room, and animates to a
/// column when the width drops below `threshold` or the text gets very large.
struct AnyLayoutAdaptiveSwitch<Content: View>: View {
    var threshold: CGFloat = 340
    var spacing: CGFloat = 12
    @ViewBuilder let content: () -> Content

    @State private var availableWidth = CGFloat.infinity
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var usesColumn: Bool {
        dynamicTypeSize.isAccessibilitySize || availableWidth < threshold
    }

    var body: some View {
        let layout = usesColumn ? AnyLayout(VStackLayout(spacing: spacing)) : AnyLayout(HStackLayout(spacing: spacing))

        layout { content() }
            // Reads the width offered by the parent, not the size of the row or column,
            // so that switching layout cannot change the measurement and loop.
            .frame(maxWidth: .infinity)
            .onGeometryChange(for: CGFloat.self, of: { $0.size.width }, action: { newWidth in
                // The first measurement is not a change the person should see animate.
                var transaction = Transaction()
                transaction.disablesAnimations = availableWidth == .infinity
                withTransaction(transaction) { availableWidth = newWidth }
            })
            .animation(reduceMotion ? nil : .smooth(duration: 0.45), value: usesColumn)
    }
}

// MARK: - Demo

struct AnyLayoutAdaptiveSwitchDemo: View {
    @State private var isWide = true
    @State private var autoPlays = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var wideBinding: Binding<Bool> {
        Binding(get: { isWide }, set: { newValue in
            autoPlays = false
            isWide = newValue
        })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
            Toggle("Wide container", isOn: wideBinding)
                .font(.headline)

            AnyLayoutAdaptiveSwitch(threshold: 300) {
                tile("Photos", systemImage: "photo.fill", color: .pink)
                tile("Music", systemImage: "music.note", color: .orange)
                tile("Maps", systemImage: "map.fill", color: .teal)
            }
            .padding(14)
            .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 24, style: .continuous))
            .frame(maxWidth: isWide ? 362 : 200)

            }
            .padding(20)
        }
        .tint(.indigo)
        .task(id: autoPlays && !reduceMotion) {
            guard autoPlays, !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.3))
                guard !Task.isCancelled else { return }
                withAnimation(.smooth(duration: 0.45)) { isWide.toggle() }
            }
        }
    }

    private func tile(_ title: String, systemImage: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .accessibilityHidden(true)
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 92)
        .background(color.gradient, in: .rect(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    AnyLayoutAdaptiveSwitchDemo()
}
