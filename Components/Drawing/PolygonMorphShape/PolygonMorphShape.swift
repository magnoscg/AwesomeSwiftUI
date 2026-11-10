// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

nonisolated enum PolygonMorphShapeForm: String, CaseIterable, Hashable {
    case square = "Square"
    case circle = "Circle"
    case star = "Star"

    /// One sample per degree, so square corners and star tips land exactly on a sample.
    static let sampleCount = 360

    /// The outline's distance from the center, from 0 to 1, in a direction measured clockwise from the top.
    func radius(atDegrees degrees: Double) -> Double {
        let radians = degrees * .pi / 180

        switch self {
        case .square:
            return 0.7071 / max(abs(cos(radians)), abs(sin(radians)))
        case .circle:
            return 0.85
        case .star:
            return Self.starRadius(atDegrees: degrees)
        }
    }

    var radii: PolygonMorphShapeRadii {
        PolygonMorphShapeRadii(
            values: (0..<Self.sampleCount).map { radius(atDegrees: Double($0) * 360 / Double(Self.sampleCount)) }
        )
    }

    /// Finds where a ray from the center crosses the straight edge from a tip to its inner corner.
    private static func starRadius(atDegrees degrees: Double) -> Double {
        let sector = 72.0
        let wrapped = degrees.truncatingRemainder(dividingBy: sector)
        let positive = wrapped < 0 ? wrapped + sector : wrapped
        let folded = min(positive, sector - positive) * .pi / 180

        let outer = 1.0
        let inner = 0.46
        let halfSector = sector / 2 * .pi / 180
        let edgeX = inner * cos(halfSector) - outer
        let edgeY = inner * sin(halfSector)

        return (outer * edgeY) / (cos(folded) * edgeY - sin(folded) * edgeX)
    }
}

/// A list of radii that SwiftUI can interpolate, which is what makes the morph work between any two forms.
nonisolated struct PolygonMorphShapeRadii: VectorArithmetic {
    var values: [Double]

    static var zero: Self { Self(values: []) }

    static func + (lhs: Self, rhs: Self) -> Self { combine(lhs, rhs, +) }
    static func - (lhs: Self, rhs: Self) -> Self { combine(lhs, rhs, -) }

    mutating func scale(by rhs: Double) {
        values = values.map { $0 * rhs }
    }

    var magnitudeSquared: Double {
        values.reduce(0) { $0 + $1 * $1 }
    }

    /// `zero` is empty, so a missing value on either side counts as 0.
    private static func combine(_ lhs: Self, _ rhs: Self, _ operation: (Double, Double) -> Double) -> Self {
        let count = max(lhs.values.count, rhs.values.count)
        return Self(
            values: (0..<count).map { index in
                operation(
                    index < lhs.values.count ? lhs.values[index] : 0,
                    index < rhs.values.count ? rhs.values[index] : 0
                )
            }
        )
    }
}

/// A shape that morphs smoothly between a square, a circle and a star when its form changes.
///
/// Every form is sampled at the same angles, so morphing is only interpolating distances.
nonisolated struct PolygonMorphShape: Shape {
    var radii: PolygonMorphShapeRadii

    init(form: PolygonMorphShapeForm) {
        radii = form.radii
    }

    var animatableData: PolygonMorphShapeRadii {
        get { radii }
        set { radii = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let count = radii.values.count
        let scale = min(rect.width, rect.height) / 2
        guard count > 0, scale > 0 else { return Path() }

        var path = Path()
        for (index, radius) in radii.values.enumerated() {
            let angle = 2 * Double.pi * Double(index) / Double(count)
            let point = CGPoint(
                x: rect.midX + radius * scale * sin(angle),
                y: rect.midY - radius * scale * cos(angle)
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Demo

struct PolygonMorphShapeDemo: View {
    @State private var form = PolygonMorphShapeForm.square
    @State private var isAutoPlaying = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var nextForm: PolygonMorphShapeForm {
        let forms = PolygonMorphShapeForm.allCases
        let index = forms.firstIndex(of: form) ?? 0
        return forms[(index + 1) % forms.count]
    }

    var body: some View {
        VStack(spacing: 36) {
            PolygonMorphShape(form: form)
                .fill(LinearGradient(colors: [.purple, .pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .pink.opacity(0.4), radius: 24, y: 12)
                .frame(maxWidth: 280, maxHeight: 280)
                .accessibilityElement()
                .accessibilityLabel(form.rawValue)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { buttons }
                VStack(spacing: 10) { buttons }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.purple.opacity(0.08).ignoresSafeArea())
        .animation(reduceMotion ? nil : .spring(duration: 0.9, bounce: 0.25), value: form)
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }

            while isAutoPlaying {
                try? await Task.sleep(for: .seconds(1.3))
                guard !Task.isCancelled, isAutoPlaying else { return }
                form = nextForm
            }
        }
    }

    private var buttons: some View {
        ForEach(PolygonMorphShapeForm.allCases, id: \.self) { option in
            Button(option.rawValue) {
                isAutoPlaying = false
                form = option
            }
            .buttonStyle(.bordered)
            .tint(option == form ? .pink : .secondary)
            .accessibilityAddTraits(option == form ? .isSelected : [])
        }
    }
}

#Preview {
    PolygonMorphShapeDemo()
}
