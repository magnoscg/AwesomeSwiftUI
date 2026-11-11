// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// Spawns an expanding ripple wherever the user taps, without blocking the view's own controls.
///
/// With Reduce Motion on, a ripple fades in place instead of expanding.
struct RippleTapEffect: ViewModifier {
    var color: Color = .white
    var maxRadius: Double = 170
    var duration: Double = 0.9
    var cornerRadius: Double = 0

    private struct Ripple: Identifiable {
        let id = UUID()
        let location: CGPoint
        let start: Date
    }

    @State private var ripples: [Ripple] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                TimelineView(.animation(paused: ripples.isEmpty)) { timeline in
                    Canvas { context, _ in
                        for ripple in ripples {
                            draw(ripple, at: timeline.date, in: context)
                        }
                    }
                }
                .clipShape(.rect(cornerRadius: cornerRadius))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .contentShape(.rect(cornerRadius: cornerRadius))
            .simultaneousGesture(SpatialTapGesture().onEnded { spawn(at: $0.location) })
    }

    private func spawn(at location: CGPoint) {
        let ripple = Ripple(location: location, start: .now)
        ripples.append(ripple)

        Task {
            try? await Task.sleep(for: .seconds(duration))
            ripples.removeAll { $0.id == ripple.id }
        }
    }

    private func draw(_ ripple: Ripple, at date: Date, in context: GraphicsContext) {
        let progress = min(max(date.timeIntervalSince(ripple.start) / duration, 0), 1)
        let eased = 1 - pow(1 - progress, 3)
        let fade = 1 - progress

        for (scale, width) in [(1.0, 2.5), (0.62, 1.5)] {
            let radius = (reduceMotion ? 0.45 : eased) * maxRadius * scale
            let circle = Path(ellipseIn: CGRect(
                x: ripple.location.x - radius,
                y: ripple.location.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
            context.fill(circle, with: .color(color.opacity(0.1 * fade)))
            context.stroke(circle, with: .color(color.opacity(0.75 * fade)), lineWidth: width)
        }
    }
}

extension View {
    /// Spawns a ripple at every tap on this view.
    func rippleTapEffect(color: Color = .white, maxRadius: Double = 170, cornerRadius: Double = 0) -> some View {
        modifier(RippleTapEffect(color: color, maxRadius: maxRadius, cornerRadius: cornerRadius))
    }
}

// MARK: - Demo

struct RippleTapEffectDemo: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.teal, .blue, Color(red: 0.14, green: 0.1, blue: 0.45)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 10) {
                Image(systemName: "hand.tap.fill")
                    .font(.largeTitle)
                    .accessibilityHidden(true)
                Text("Tap Anywhere")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
            }
            .foregroundStyle(.white)
        }
        .rippleTapEffect()
        .ignoresSafeArea()
    }
}

#Preview {
    RippleTapEffectDemo()
}
