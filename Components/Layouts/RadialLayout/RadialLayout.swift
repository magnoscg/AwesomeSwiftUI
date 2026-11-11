// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

nonisolated enum RadialLayoutMath {
    /// Evenly spaced angles, the first one at `start`.
    static func angles(count: Int, start: Angle = .degrees(-90)) -> [Angle] {
        guard count > 0 else { return [] }
        let step = 360.0 / Double(count)
        return (0..<count).map { .degrees(start.degrees + Double($0) * step) }
    }

    static func point(at angle: Angle, center: CGPoint, radius: CGFloat) -> CGPoint {
        CGPoint(
            x: center.x + radius * cos(angle.radians),
            y: center.y + radius * sin(angle.radians)
        )
    }
}

/// A layout that spreads its views around a circle.
///
/// Change the number of views inside `withAnimation` and the others glide to their new places.
/// Leave `radius` as `nil` to fill the space it is given.
struct RadialLayout: Layout {
    var radius: CGFloat?
    var startAngle: Angle = .degrees(-90)

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        if let radius {
            let side = 2 * radius + largestSide(of: subviews)
            return CGSize(width: side, height: side)
        }
        let size = proposal.replacingUnspecifiedDimensions(by: CGSize(width: 280, height: 280))
        let side = min(size.width, size.height)
        return CGSize(width: side, height: side)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let circleRadius = radius ?? max(min(bounds.width, bounds.height) / 2 - largestSide(of: subviews) / 2, 0)

        for (subview, angle) in zip(subviews, RadialLayoutMath.angles(count: subviews.count, start: startAngle)) {
            subview.place(
                at: RadialLayoutMath.point(at: angle, center: center, radius: circleRadius),
                anchor: .center,
                proposal: .unspecified
            )
        }
    }

    private func largestSide(of subviews: Subviews) -> CGFloat {
        subviews.map {
            let size = $0.sizeThatFits(.unspecified)
            return max(size.width, size.height)
        }.max() ?? 0
    }
}

// MARK: - Demo

private struct DemoApp: Identifiable {
    var id: String { name }
    let name: String
    let symbol: String
    let color: Color
}

struct RadialLayoutDemo: View {
    private static let all = [
        DemoApp(name: "Music", symbol: "music.note", color: .pink),
        DemoApp(name: "Photos", symbol: "photo.fill", color: .orange),
        DemoApp(name: "Maps", symbol: "map.fill", color: .green),
        DemoApp(name: "Mail", symbol: "envelope.fill", color: .blue),
        DemoApp(name: "Notes", symbol: "note.text", color: .yellow),
        DemoApp(name: "Weather", symbol: "cloud.sun.fill", color: .cyan),
        DemoApp(name: "Health", symbol: "heart.fill", color: .red),
        DemoApp(name: "Clock", symbol: "clock.fill", color: .purple),
        DemoApp(name: "Camera", symbol: "camera.fill", color: .teal),
    ]

    @State private var count = 5
    @ScaledMetric(relativeTo: .title2) private var iconSize = 64.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 40) {
            ZStack {
                RadialLayout {
                    ForEach(Self.all.prefix(count)) { app in
                        Image(systemName: app.symbol)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: iconSize, height: iconSize)
                            .background(app.color.gradient, in: .circle)
                            .accessibilityLabel(app.name)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                Text("\(count)")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .contentTransition(.numericText(value: Double(count)))
                    .accessibilityLabel("\(count) apps")
            }
            .frame(maxWidth: 340, maxHeight: 340)

            HStack(spacing: 14) {
                Button("Remove", systemImage: "minus") { change(by: -1) }
                    .disabled(count == 1)
                Button("Add", systemImage: "plus") { change(by: 1) }
                    .disabled(count == Self.all.count)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [.indigo.opacity(0.18), .teal.opacity(0.14)], startPoint: .top, endPoint: .bottom))
    }

    private func change(by amount: Int) {
        withAnimation(reduceMotion ? nil : .bouncy(duration: 0.55)) { count += amount }
    }
}

#Preview {
    RadialLayoutDemo()
}
