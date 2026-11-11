// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

struct ColorSwatchPickerOption: Hashable, Identifiable {
    let name: String
    let color: Color

    var id: String { name }
}

/// A grid of color swatches where the selected one grows a ring.
///
/// With Reduce Motion on, the ring fades in without growing.
struct ColorSwatchPicker: View {
    let options: [ColorSwatchPickerOption]
    @Binding var selection: ColorSwatchPickerOption

    @ScaledMetric(relativeTo: .title) private var swatchSize = 48.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: swatchSize), spacing: 12)], spacing: 12) {
            ForEach(options) { option in
                swatch(option)
            }
        }
        .animation(reduceMotion ? .easeOut(duration: 0.15) : .spring(duration: 0.35, bounce: 0.5), value: selection)
    }

    private func swatch(_ option: ColorSwatchPickerOption) -> some View {
        let isSelected = option == selection

        return Button {
            selection = option
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(option.color, lineWidth: 3)
                    .scaleEffect(isSelected || reduceMotion ? 1 : 0.5)
                    .opacity(isSelected ? 1 : 0)

                Circle()
                    .fill(option.color.gradient)
                    .padding(isSelected ? 8 : 4)
            }
            .frame(width: swatchSize, height: swatchSize)
            .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Demo

struct ColorSwatchPickerDemo: View {
    private static let options = [
        ColorSwatchPickerOption(name: "Coral", color: .red),
        ColorSwatchPickerOption(name: "Amber", color: .orange),
        ColorSwatchPickerOption(name: "Mint", color: .mint),
        ColorSwatchPickerOption(name: "Sky", color: .cyan),
        ColorSwatchPickerOption(name: "Indigo", color: .indigo),
        ColorSwatchPickerOption(name: "Rose", color: .pink),
    ]

    @State private var selection = options[2]

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "paintpalette.fill")
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .background(selection.color.gradient, in: .rect(cornerRadius: 28))
                .animation(.easeInOut(duration: 0.3), value: selection)
                .accessibilityHidden(true)

            Text("Pick an accent")
                .font(.title2.bold())

            ColorSwatchPicker(options: Self.options, selection: $selection)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ColorSwatchPickerDemo()
}
