// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A transition that reveals a view through a circle growing from a point.
/// Use it as `.transition(.circleReveal(from: .bottomTrailing))`.
///
/// With Reduce Motion on, the view fades instead.
struct CircleRevealTransition: Transition {
    var origin: UnitPoint = .center

    func body(content: Content, phase: TransitionPhase) -> some View {
        content.modifier(CircleRevealEffect(origin: origin, isIdentity: phase.isIdentity))
    }
}

extension Transition where Self == CircleRevealTransition {
    static func circleReveal(from origin: UnitPoint = .center) -> CircleRevealTransition {
        CircleRevealTransition(origin: origin)
    }
}

enum CircleRevealTransitionGeometry {
    /// The radius of the smallest circle centered on `origin` that covers the whole of `size`.
    static func coverRadius(from origin: UnitPoint, in size: CGSize) -> CGFloat {
        let horizontal = max(origin.x, 1 - origin.x) * size.width
        let vertical = max(origin.y, 1 - origin.y) * size.height
        return hypot(horizontal, vertical)
    }
}

private struct CircleRevealEffect: ViewModifier {
    let origin: UnitPoint
    let isIdentity: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .clipShape(CircleRevealShape(origin: origin, progress: isIdentity || reduceMotion ? 1 : 0))
            .opacity(reduceMotion && !isIdentity ? 0 : 1)
    }
}

private struct CircleRevealShape: Shape {
    let origin: UnitPoint
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let radius = CircleRevealTransitionGeometry.coverRadius(from: origin, in: rect.size) * progress
        let center = CGPoint(x: rect.minX + rect.width * origin.x, y: rect.minY + rect.height * origin.y)
        return Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    }
}

// MARK: - Demo

struct CircleRevealTransitionDemo: View {
    @State private var isDark = false

    private let origin = UnitPoint(x: 0.5, y: 0.78)

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                scene(colors: [.cyan, .blue], systemImage: "sun.max.fill", title: "Day")
                    .accessibilityHidden(isDark)

                if isDark {
                    scene(colors: [.indigo, .black], systemImage: "moon.stars.fill", title: "Night")
                        .transition(.circleReveal(from: origin))
                }

                Button(isDark ? "Sunrise" : "Sunset") {
                    withAnimation(.easeInOut(duration: 0.8)) { isDark.toggle() }
                }
                .font(.headline)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.white)
                .position(x: proxy.size.width * origin.x, y: proxy.size.height * origin.y)
            }
        }
        .ignoresSafeArea()
    }

    private func scene(colors: [Color], systemImage: String, title: String) -> some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)

            VStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(.largeTitle, weight: .semibold))
                    .imageScale(.large)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
            }
            .foregroundStyle(.white)
        }
    }
}

#Preview {
    CircleRevealTransitionDemo()
}
