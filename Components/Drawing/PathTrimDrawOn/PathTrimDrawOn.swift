// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// Draws any shape along its path when `isDrawn` turns true, over a faint guide of the same shape.
///
/// With Reduce Motion on, the shape appears at once.
struct PathTrimDrawOn<Outline: Shape>: View {
    let shape: Outline
    let isDrawn: Bool
    var label: LocalizedStringResource = "Logo"
    var colors: [Color] = [.pink, .orange]
    var lineWidth: CGFloat = 8
    var duration: Double = 1.6

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var style: StrokeStyle {
        StrokeStyle(lineWidth: max(lineWidth, 0), lineCap: .round, lineJoin: .round)
    }

    var body: some View {
        ZStack {
            shape.stroke(.quaternary, style: style)

            shape
                .trim(from: 0, to: isDrawn ? 1 : 0)
                .stroke(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing), style: style)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: duration > 0 ? duration : 0.01), value: isDrawn)
        .accessibilityElement()
        .accessibilityLabel(label)
    }
}

/// A heart with a pulse line through it, scaled to fit any rectangle.
nonisolated struct PathTrimDrawOnHeartbeat: Shape {
    /// The margin the heart's curves keep from the left and the top of the unit square.
    private static let inset: CGFloat = 0.04

    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        guard side > 0 else { return Path() }

        let origin = CGPoint(x: rect.midX - side / 2, y: rect.midY - side / 2)
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x * side, y: origin.y + y * side)
        }

        var path = Path()
        path.move(to: point(0.5, 0.92))
        path.addCurve(to: point(Self.inset, 0.36), control1: point(0.2, 0.7), control2: point(Self.inset, 0.54))
        path.addCurve(to: point(0.5, 0.24), control1: point(Self.inset, 0.08), control2: point(0.4, Self.inset))
        path.addCurve(to: point(0.96, 0.36), control1: point(0.6, Self.inset), control2: point(0.96, 0.08))
        path.addCurve(to: point(0.5, 0.92), control1: point(0.96, 0.54), control2: point(0.8, 0.7))

        path.move(to: point(0.16, 0.5))
        path.addLine(to: point(0.36, 0.5))
        path.addLine(to: point(0.44, 0.32))
        path.addLine(to: point(0.55, 0.68))
        path.addLine(to: point(0.63, 0.5))
        path.addLine(to: point(0.84, 0.5))
        return path
    }
}

// MARK: - Demo

struct PathTrimDrawOnDemo: View {
    @State private var isDrawn = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 28) {
            PathTrimDrawOn(shape: PathTrimDrawOnHeartbeat(), isDrawn: isDrawn, label: "Heart with a pulse line", duration: 1.5)
                .frame(maxWidth: 280, maxHeight: 280)

            Text("Heartbeat")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [.pink.opacity(0.14), .orange.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .task(id: reduceMotion) {
            guard !reduceMotion else {
                isDrawn = true
                return
            }

            while !Task.isCancelled {
                isDrawn = true
                try? await Task.sleep(for: .seconds(2.2))
                guard !Task.isCancelled else { return }
                isDrawn = false
                try? await Task.sleep(for: .seconds(1.8))
            }
        }
    }
}

#Preview {
    PathTrimDrawOnDemo()
}
