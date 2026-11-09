// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

struct DrawingPadSpeedBrushPoint: Equatable {
    var location: CGPoint
    var width: CGFloat
}

enum DrawingPadSpeedBrushMath {
    /// The stroke width for a finger speed in points per second: thick when slow, thin when fast.
    static func width(speed: CGFloat, thin: CGFloat, thick: CGFloat, fullSpeed: CGFloat) -> CGFloat {
        let thinnest = max(thin, 0.5)
        let thickest = max(thick, thinnest)
        guard fullSpeed > 0, speed.isFinite else { return thickest }

        let fraction = min(max(speed, 0) / fullSpeed, 1)
        return thickest + (thinnest - thickest) * fraction
    }

    /// Moves part of the way to the target, so the width does not jump between samples.
    static func smoothed(from previous: CGFloat, to target: CGFloat, factor: CGFloat = 0.3) -> CGFloat {
        previous + (target - previous) * min(max(factor, 0), 1)
    }
}

/// A drawing pad whose stroke gets thinner as the finger moves faster, like a brush pen.
///
/// A stroke the system interrupts is kept up to the point where it stopped.
struct DrawingPadSpeedBrush: View {
    @Binding var strokes: [[DrawingPadSpeedBrushPoint]]
    var color: Color = .primary
    var thinWidth: CGFloat = 2
    var thickWidth: CGFloat = 16
    var fullSpeed: CGFloat = 1400

    @State private var currentStroke: [DrawingPadSpeedBrushPoint] = []
    @State private var lastSampleTime: Date?
    @GestureState private var isDrawing = false

    var body: some View {
        Canvas { context, _ in
            let shading = GraphicsContext.Shading.color(color)
            for stroke in strokes {
                Self.draw(stroke, shading: shading, in: context)
            }
            Self.draw(currentStroke, shading: shading, in: context)
        }
        .clipped()
        .contentShape(.rect)
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isDrawing) { _, state, _ in state = true }
                .onChanged(addSample)
        )
        .onChange(of: isDrawing) { _, drawing in
            if !drawing { finishStroke() }
        }
        .accessibilityElement()
        .accessibilityLabel("Drawing pad")
        .accessibilityValue("\(strokes.count) strokes")
        .accessibilityAddTraits(.allowsDirectInteraction)
    }

    private func addSample(_ value: DragGesture.Value) {
        guard let last = currentStroke.last, let lastTime = lastSampleTime else {
            let width = DrawingPadSpeedBrushMath.width(speed: 0, thin: thinWidth, thick: thickWidth, fullSpeed: fullSpeed)
            currentStroke = [DrawingPadSpeedBrushPoint(location: value.location, width: width)]
            lastSampleTime = value.time
            return
        }

        let distance = hypot(value.location.x - last.location.x, value.location.y - last.location.y)
        guard distance >= 1 else { return }

        let seconds = value.time.timeIntervalSince(lastTime)
        let speed = seconds > 0 ? distance / seconds : fullSpeed
        let target = DrawingPadSpeedBrushMath.width(speed: speed, thin: thinWidth, thick: thickWidth, fullSpeed: fullSpeed)
        currentStroke.append(
            DrawingPadSpeedBrushPoint(
                location: value.location,
                width: DrawingPadSpeedBrushMath.smoothed(from: last.width, to: target)
            )
        )
        lastSampleTime = value.time
    }

    private func finishStroke() {
        lastSampleTime = nil
        guard !currentStroke.isEmpty else { return }
        strokes.append(currentStroke)
        currentStroke = []
    }

    /// Each sample becomes one curved segment with its own width.
    private static func draw(_ stroke: [DrawingPadSpeedBrushPoint], shading: GraphicsContext.Shading, in context: GraphicsContext) {
        guard let first = stroke.first else { return }

        guard stroke.count > 1 else {
            let radius = first.width / 2
            let dot = CGRect(x: first.location.x - radius, y: first.location.y - radius, width: first.width, height: first.width)
            context.fill(Path(ellipseIn: dot), with: shading)
            return
        }

        var start = first.location
        for index in 1..<stroke.count {
            let control = stroke[index]
            var end = control.location
            if index + 1 < stroke.count {
                let next = stroke[index + 1].location
                end = CGPoint(x: (control.location.x + next.x) / 2, y: (control.location.y + next.y) / 2)
            }

            var segment = Path()
            segment.move(to: start)
            segment.addQuadCurve(to: end, control: control.location)
            context.stroke(segment, with: shading, style: StrokeStyle(lineWidth: control.width, lineCap: .round, lineJoin: .round))
            start = end
        }
    }
}

// MARK: - Demo

struct DrawingPadSpeedBrushDemo: View {
    @State private var strokes: [[DrawingPadSpeedBrushPoint]] = []

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Speed Brush")
                    .font(.system(.title, design: .rounded, weight: .bold))

                Text("Slow is thick, fast is thin")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            DrawingPadSpeedBrush(strokes: $strokes, color: .indigo)
                .background(.white, in: .rect(cornerRadius: 24))
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)

            Button("Clear", systemImage: "trash") {
                strokes = []
            }
            .buttonStyle(.bordered)
            .disabled(strokes.isEmpty)
        }
        .padding(20)
        .background(Color.indigo.opacity(0.1).ignoresSafeArea())
    }
}

#Preview {
    DrawingPadSpeedBrushDemo()
}
