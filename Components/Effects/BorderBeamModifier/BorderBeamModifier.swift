// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

enum BorderBeamModifierMath {
    /// How far around the border the beam's head is, from 0 up to 1.
    static func head(time: Double, duration: Double) -> Double {
        guard duration > 0, time.isFinite else { return 0 }
        return wrapped(time / duration)
    }

    /// The trim ranges that cover `start` to `end` on a closed path, in two parts across the seam.
    static func trims(from start: Double, to end: Double) -> [ClosedRange<Double>] {
        let from = wrapped(start)
        let to = wrapped(end)
        if from == to { return [] }
        if from < to { return [from...to] }
        return to > 0 ? [from...1, 0...to] : [from...1]
    }

    private static func wrapped(_ value: Double) -> Double {
        value - floor(value)
    }
}

/// A light beam that travels around a rounded border at a steady speed, with a fading tail.
///
/// With Reduce Motion on, the beam stays still.
struct BorderBeamModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var lineWidth: CGFloat = 2
    var head: Color = .cyan
    var tail: Color = .purple
    var duration: Double = 3.5
    var length: Double = 0.3

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion)) { timeline in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate

                Canvas { context, size in
                    drawBeam(in: context, size: size, position: BorderBeamModifierMath.head(time: time, duration: duration))
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private func drawBeam(in context: GraphicsContext, size: CGSize, position: Double) {
        let width = max(lineWidth, 0)
        let rect = CGRect(origin: .zero, size: size).insetBy(dx: width / 2, dy: width / 2)
        let beam = min(max(length, 0), 1)
        guard width > 0, beam > 0, rect.width > 0, rect.height > 0 else { return }

        let radius = min(max(cornerRadius - width / 2, 0), min(rect.width, rect.height) / 2)
        let border = RoundedRectangle(cornerRadius: radius, style: .continuous).path(in: rect)

        let slices = 32
        var segments: [(path: Path, shading: GraphicsContext.Shading)] = []
        for slice in 0..<slices {
            let fraction = Double(slice + 1) / Double(slices)
            let start = position - beam * (1 - Double(slice) / Double(slices))
            let end = position - beam * (1 - fraction) + 0.001
            let shading = GraphicsContext.Shading.color(tail.mix(with: head, by: fraction).opacity(fraction))

            for trim in BorderBeamModifierMath.trims(from: start, to: end) {
                segments.append((border.trimmedPath(from: trim.lowerBound, to: trim.upperBound), shading))
            }
        }

        var glow = context
        glow.addFilter(.blur(radius: width * 2.5))
        glow.drawLayer { layer in
            for segment in segments {
                layer.stroke(segment.path, with: segment.shading, lineWidth: width * 2)
            }
        }

        for segment in segments {
            context.stroke(segment.path, with: segment.shading, lineWidth: width)
        }
    }
}

extension View {
    /// Sends a light beam around this view's border. Match `cornerRadius` to the view's shape.
    func borderBeam(
        cornerRadius: CGFloat = 20,
        lineWidth: CGFloat = 2,
        head: Color = .cyan,
        tail: Color = .purple,
        duration: Double = 3.5,
        length: Double = 0.3
    ) -> some View {
        modifier(
            BorderBeamModifier(
                cornerRadius: cornerRadius,
                lineWidth: lineWidth,
                head: head,
                tail: tail,
                duration: duration,
                length: length
            )
        )
    }
}

// MARK: - Demo

struct BorderBeamModifierDemo: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "bolt.fill")
                        .font(.title)
                        .foregroundStyle(.cyan)
                        .accessibilityHidden(true)

                    Text("Introducing Beam")
                        .font(.system(.title, design: .rounded, weight: .bold))

                    Text("A quiet way to draw the eye to what matters most on the screen.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .foregroundStyle(.white)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.07), in: .rect(cornerRadius: 28, style: .continuous))
                .borderBeam(cornerRadius: 28, lineWidth: 2.5)

                Text("Get early access")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.07), in: .capsule)
                    .borderBeam(cornerRadius: 200, head: .orange, tail: .pink, duration: 2.5, length: 0.4)
            }
            .padding(24)
        }
        .defaultScrollAnchor(.center, for: .alignment)
        .background(Color(red: 0.05, green: 0.05, blue: 0.1).ignoresSafeArea())
    }
}

#Preview {
    BorderBeamModifierDemo()
}
