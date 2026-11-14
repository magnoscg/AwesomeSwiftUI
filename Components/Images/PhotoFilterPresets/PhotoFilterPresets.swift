// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

struct PhotoFilterPreset: Identifiable, Hashable, Sendable {
    let name: String
    var saturation = 1.0
    var contrast = 1.0
    var brightness = 0.0
    var hue = 0.0
    var tint = Color.white

    var id: String { name }

    static let original = PhotoFilterPreset(name: "Original")
    static let all = [
        original,
        PhotoFilterPreset(name: "Mono", saturation: 0, contrast: 1.15),
        PhotoFilterPreset(name: "Warm", saturation: 1.15, tint: Color(red: 1, green: 0.86, blue: 0.68)),
        PhotoFilterPreset(name: "Cool", saturation: 0.95, tint: Color(red: 0.7, green: 0.86, blue: 1)),
        PhotoFilterPreset(name: "Punch", saturation: 1.6, contrast: 1.3),
        PhotoFilterPreset(name: "Fade", saturation: 0.65, contrast: 0.8, brightness: 0.08),
    ]
}

extension View {
    func filtered(by preset: PhotoFilterPreset) -> some View {
        colorMultiply(preset.tint)
            .saturation(preset.saturation)
            .contrast(preset.contrast)
            .brightness(preset.brightness)
            .hueRotation(.degrees(preset.hue))
    }
}

/// A photo with a row of preset thumbnails that apply a look using SwiftUI modifiers.
///
/// The row scrolls sideways and its tiles grow with Dynamic Type. With Reduce Motion on, a new
/// look appears without a crossfade.
struct PhotoFilterPresets: View {
    let image: Image
    @Binding var selection: PhotoFilterPreset
    var presets = PhotoFilterPreset.all

    @ScaledMetric(relativeTo: .caption) private var tileSize = 72.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 20) {
            image
                .resizable()
                .scaledToFit()
                .filtered(by: selection)
                .clipShape(.rect(cornerRadius: 24))
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 16)
                .accessibilityLabel("Photo with the \(selection.name) look")

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(presets) { preset in
                        tile(preset)
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
            .fixedSize(horizontal: false, vertical: true)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: selection)
    }

    private func tile(_ preset: PhotoFilterPreset) -> some View {
        let isSelected = preset == selection

        return Button {
            selection = preset
        } label: {
            VStack(spacing: 6) {
                Color.clear
                    .frame(width: tileSize, height: tileSize)
                    .overlay {
                        image
                            .resizable()
                            .scaledToFill()
                            .filtered(by: preset)
                    }
                    .clipShape(.rect(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 3)
                    }

                Text(preset.name)
                    .font(.caption.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(preset.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Demo

struct PhotoFilterPresetsDemo: View {
    @State private var selection = PhotoFilterPreset.original

    private let photo = demoPhoto()

    var body: some View {
        PhotoFilterPresets(image: photo, selection: $selection)
            .padding(.vertical, 16)
    }
}

private func demoPhoto() -> Image {
    let size = CGSize(width: 900, height: 1125)
    return Image(size: size, label: Text("Flower field")) { context in
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(Gradient(colors: [.cyan, .white]), startPoint: .zero, endPoint: CGPoint(x: 0, y: 620))
        )
        context.fill(Path(ellipseIn: CGRect(x: 610, y: 110, width: 170, height: 170)), with: .color(.yellow))
        context.fill(
            Path(CGRect(x: 0, y: 620, width: 900, height: 505)),
            with: .linearGradient(Gradient(colors: [.green, Color(red: 0, green: 0.35, blue: 0.2)]), startPoint: CGPoint(x: 0, y: 620), endPoint: CGPoint(x: 0, y: 1125))
        )

        let colors: [Color] = [.pink, .red, .orange, .purple]
        for index in 0..<36 {
            let x = CGFloat(index * 257 % 860) + 10
            let y = 660 + CGFloat(index * 131 % 430)
            let side = 30 + CGFloat(index % 4) * 14
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: side, height: side)), with: .color(colors[index % colors.count]))
        }
    }
}

#Preview {
    PhotoFilterPresetsDemo()
}
