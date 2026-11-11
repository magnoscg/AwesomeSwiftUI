// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

struct PhotoAdjustmentSlidersValues: Equatable, Sendable {
    var brightness = 0.0
    var contrast = 1.0
    var saturation = 1.0
    var hue = 0.0
}

extension View {
    func adjusted(by values: PhotoAdjustmentSlidersValues) -> some View {
        saturation(values.saturation)
            .contrast(values.contrast)
            .brightness(values.brightness)
            .hueRotation(.degrees(values.hue))
    }
}

/// Brightness, contrast, saturation and hue sliders that update a photo live as they move.
///
/// The whole view scrolls, so every slider stays reachable at the largest text sizes.
struct PhotoAdjustmentSliders: View {
    let image: Image
    @Binding var values: PhotoAdjustmentSlidersValues
    var maxImageHeight: CGFloat = 340

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                image
                    .resizable()
                    .scaledToFit()
                    .adjusted(by: values)
                    .clipShape(.rect(cornerRadius: 20))
                    .frame(maxHeight: max(maxImageHeight, 0))

                VStack(spacing: 12) {
                    row("Brightness", $values.brightness, in: -0.5...0.5, shown: percent(values.brightness))
                    row("Contrast", $values.contrast, in: 0.5...1.5, shown: percent(values.contrast - 1))
                    row("Saturation", $values.saturation, in: 0...2, shown: percent(values.saturation - 1))
                    row("Hue", $values.hue, in: -180...180, shown: "\(Int(values.hue.rounded()))°")
                }

                Button("Reset", systemImage: "arrow.counterclockwise") {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                        values = PhotoAdjustmentSlidersValues()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(values == PhotoAdjustmentSlidersValues())
            }
            .padding(16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func row(_ title: String, _ value: Binding<Double>, in range: ClosedRange<Double>, shown: String) -> some View {
        VStack(spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                Text(shown)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .accessibilityHidden(true)

            Slider(value: value, in: range)
                .accessibilityLabel(title)
                .accessibilityValue(shown)
        }
    }

    private func percent(_ value: Double) -> String {
        let whole = Int((value * 100).rounded())
        return whole > 0 ? "+\(whole)%" : "\(whole)%"
    }
}

// MARK: - Demo

struct PhotoAdjustmentSlidersDemo: View {
    @State private var values = PhotoAdjustmentSlidersValues()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let photo = demoPhoto()

    var body: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .horizontal) {
                looks
                ScrollView(.horizontal) { looks }
            }
            .padding(.top, 8)

            PhotoAdjustmentSliders(image: photo, values: $values)
        }
    }

    private var looks: some View {
        HStack(spacing: 8) {
            look("Vivid", PhotoAdjustmentSlidersValues(brightness: 0.05, contrast: 1.2, saturation: 1.7))
            look("Noir", PhotoAdjustmentSlidersValues(brightness: -0.05, contrast: 1.35, saturation: 0))
            look("Dream", PhotoAdjustmentSlidersValues(brightness: 0.1, contrast: 0.85, saturation: 1.2, hue: 60))
        }
    }

    private func look(_ title: String, _ target: PhotoAdjustmentSlidersValues) -> some View {
        Button(title) {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.6)) { values = target }
        }
        .buttonStyle(.borderedProminent)
    }
}

private func demoPhoto() -> Image {
    let size = CGSize(width: 1000, height: 800)
    return Image(size: size, label: Text("Lake at sunrise")) { context in
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(Gradient(colors: [.blue, .pink, .orange]), startPoint: .zero, endPoint: CGPoint(x: 0, y: 460))
        )
        context.fill(Path(ellipseIn: CGRect(x: 400, y: 240, width: 200, height: 200)), with: .color(.yellow))
        context.fill(
            Path(CGRect(x: 0, y: 460, width: 1000, height: 340)),
            with: .linearGradient(Gradient(colors: [.orange, .teal, .indigo]), startPoint: CGPoint(x: 0, y: 460), endPoint: CGPoint(x: 0, y: 800))
        )

        var hills = Path()
        hills.move(to: CGPoint(x: 0, y: 470))
        hills.addCurve(to: CGPoint(x: 1000, y: 470), control1: CGPoint(x: 300, y: 250), control2: CGPoint(x: 700, y: 620))
        hills.closeSubpath()
        context.fill(hills, with: .color(.green.opacity(0.8)))
    }
}

#Preview {
    PhotoAdjustmentSlidersDemo()
}
