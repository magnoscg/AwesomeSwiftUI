// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// Two stacked images split by a handle you drag to compare them.
///
/// `position` runs from 0, all after, to 1, all before. VoiceOver adjusts it by swiping up or down.
struct BeforeAfterSlider: View {
    let before: Image
    let after: Image
    @Binding var position: Double
    var beforeTitle = "Before"
    var afterTitle = "After"

    @ScaledMetric(relativeTo: .body) private var knobSize = 44.0
    @Environment(\.layoutDirection) private var layoutDirection

    private var clamped: Double { min(max(position, 0), 1) }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let handleX = size.width * clamped

            ZStack {
                photo(after, in: size)
                photo(before, in: size)
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: handleX)
                    }
                handle(height: size.height)
                    .position(x: handleX, y: size.height / 2)
            }
            .overlay(alignment: .topLeading) { tag(beforeTitle).opacity(min(clamped / 0.25, 1)) }
            .overlay(alignment: .topTrailing) { tag(afterTitle).opacity(min((1 - clamped) / 0.25, 1)) }
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { value in
                    guard size.width > 0 else { return }
                    // Gestures report screen points, but the layout mirrors in right-to-left layouts.
                    let x = layoutDirection == .rightToLeft ? size.width - value.location.x : value.location.x
                    position = min(max(x / size.width, 0), 1)
                }
            )
        }
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(beforeTitle) and \(afterTitle) comparison")
        .accessibilityValue("\(Int(clamped * 100)) percent \(beforeTitle)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: position = min(clamped + 0.1, 1)
            case .decrement: position = max(clamped - 0.1, 0)
            @unknown default: break
            }
        }
    }

    private func photo(_ image: Image, in size: CGSize) -> some View {
        image
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .clipped()
    }

    private func handle(height: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(.white)
                .frame(width: 3, height: height)
            Circle()
                .fill(.white)
                .frame(width: knobSize, height: knobSize)
                .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
            Image(systemName: "arrow.left.and.right")
                .font(.body.weight(.bold))
                .foregroundStyle(.black.opacity(0.7))
        }
    }

    private func tag(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.black.opacity(0.5), in: .capsule)
            .padding(12)
    }
}

// MARK: - Demo

struct BeforeAfterSliderDemo: View {
    @State private var position = 0.5

    private let before = demoPhoto(sky: [Color(white: 0.55), Color(white: 0.78)], hill: Color(white: 0.34), label: "Flat landscape")
    private let after = demoPhoto(sky: [.indigo, .pink, .orange], hill: Color(red: 0.13, green: 0.16, blue: 0.4), label: "Graded landscape")

    var body: some View {
        BeforeAfterSlider(before: before, after: after, position: $position)
            .aspectRatio(3 / 4, contentMode: .fit)
            .clipShape(.rect(cornerRadius: 24))
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private func demoPhoto(sky: [Color], hill: Color, label: String) -> Image {
    let size = CGSize(width: 900, height: 1200)
    return Image(size: size, label: Text(label)) { context in
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(Gradient(colors: sky), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
        )
        context.fill(Path(ellipseIn: CGRect(x: 540, y: 220, width: 200, height: 200)), with: .color(.white.opacity(0.85)))

        var ridge = Path()
        ridge.move(to: CGPoint(x: 0, y: size.height))
        ridge.addLine(to: CGPoint(x: 0, y: 760))
        ridge.addCurve(to: CGPoint(x: size.width, y: 660), control1: CGPoint(x: 300, y: 480), control2: CGPoint(x: 600, y: 1020))
        ridge.addLine(to: CGPoint(x: size.width, y: size.height))
        ridge.closeSubpath()
        context.fill(ridge, with: .color(hill))
    }
}

#Preview {
    BeforeAfterSliderDemo()
}
