// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

struct Globe3DWireframePin {
    var latitude: Double
    var longitude: Double
}

/// A wireframe globe drawn on a Canvas. Drag it to spin and tilt it.
///
/// With Reduce Motion on, it stops spinning by itself and only moves with the finger.
struct Globe3DWireframe: View {
    var meridians = 12
    var parallels = 7
    var color: Color = .cyan
    var pins: [Globe3DWireframePin] = []
    var autoRotates = true
    var label = "Globe"

    @State private var yaw = 0.0
    @State private var pitch = 0.35
    @GestureState private var drag = CGSize.zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let radiansPerPoint = 0.008
    private var isSpinning: Bool { autoRotates && !reduceMotion }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isSpinning)) { context in
            let spin = isSpinning ? context.date.timeIntervalSinceReferenceDate * 0.35 : 0
            let currentYaw = yaw + spin + drag.width * radiansPerPoint
            let currentPitch = Globe3DWireframeMath.clampedPitch(pitch + drag.height * radiansPerPoint)

            Canvas { canvas, size in
                let radius = min(size.width, size.height) / 2 * 0.94
                guard radius > 0 else { return }
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let disc = Path(ellipseIn: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
                let wires = Globe3DWireframeMath.wires(
                    meridians: meridians,
                    parallels: parallels,
                    yaw: currentYaw,
                    pitch: currentPitch,
                    center: center,
                    radius: radius
                )
                let lineWidth = max(0.6, radius * 0.006)

                canvas.stroke(wires.back, with: .color(color.opacity(0.18)), lineWidth: lineWidth)
                canvas.fill(disc, with: .radialGradient(
                    Gradient(colors: [color.opacity(0.22), color.opacity(0.04)]),
                    center: CGPoint(x: center.x - radius * 0.3, y: center.y - radius * 0.3),
                    startRadius: 0,
                    endRadius: radius * 1.3
                ))
                canvas.stroke(wires.front, with: .color(color.opacity(0.85)), lineWidth: lineWidth)
                canvas.stroke(disc, with: .color(color.opacity(0.6)), lineWidth: lineWidth * 1.5)

                for pin in pins {
                    let point = Globe3DWireframeMath.project(
                        latitude: pin.latitude,
                        longitude: pin.longitude,
                        yaw: currentYaw,
                        pitch: currentPitch
                    )
                    guard point.z > 0 else { continue }
                    let screen = CGPoint(x: center.x + point.x * radius, y: center.y - point.y * radius)
                    let glow = radius * 0.05
                    let dot = radius * 0.018
                    canvas.fill(
                        Path(ellipseIn: CGRect(x: screen.x - glow, y: screen.y - glow, width: glow * 2, height: glow * 2)),
                        with: .color(.white.opacity(0.25))
                    )
                    canvas.fill(
                        Path(ellipseIn: CGRect(x: screen.x - dot, y: screen.y - dot, width: dot * 2, height: dot * 2)),
                        with: .color(.white)
                    )
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(.circle)
        .gesture(
            DragGesture(minimumDistance: 4)
                .updating($drag) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    yaw += value.translation.width * radiansPerPoint
                    pitch = Globe3DWireframeMath.clampedPitch(pitch + value.translation.height * radiansPerPoint)
                }
        )
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityValue("Rotated \(Globe3DWireframeMath.degrees(yaw)) degrees")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: yaw += .pi / 12
            case .decrement: yaw -= .pi / 12
            @unknown default: break
            }
        }
    }
}

enum Globe3DWireframeMath {
    struct Point {
        var x: Double
        var y: Double
        var z: Double
    }

    static let maximumPitch = 1.4

    static func clampedPitch(_ pitch: Double) -> Double {
        min(max(pitch, -maximumPitch), maximumPitch)
    }

    /// The rotation as a whole number of degrees from 0 to 359.
    static func degrees(_ radians: Double) -> Int {
        guard radians.isFinite else { return 0 }
        let degrees = (radians * 180 / .pi).truncatingRemainder(dividingBy: 360)
        return (Int(degrees.rounded()) + 360) % 360
    }

    /// Turns a point of the sphere around its axis, then tilts the sphere toward the viewer.
    /// `x` points right, `y` points up and `z` points at the viewer.
    static func project(latitude: Double, longitude: Double, yaw: Double, pitch: Double) -> Point {
        let lat = latitude * .pi / 180
        let lon = longitude * .pi / 180 + yaw
        let x = cos(lat) * sin(lon)
        let y = sin(lat)
        let z = cos(lat) * cos(lon)
        return Point(x: x, y: y * cos(pitch) - z * sin(pitch), z: y * sin(pitch) + z * cos(pitch))
    }

    /// The globe's lines, split into the half that faces the viewer and the half behind it.
    static func wires(
        meridians: Int,
        parallels: Int,
        yaw: Double,
        pitch: Double,
        center: CGPoint,
        radius: Double
    ) -> (front: Path, back: Path) {
        var front = Path()
        var back = Path()

        func addLine(samples: Int, coordinate: (Double) -> (latitude: Double, longitude: Double)) {
            var previous: Point?
            for sample in 0...samples {
                let position = coordinate(Double(sample) / Double(samples))
                let point = project(latitude: position.latitude, longitude: position.longitude, yaw: yaw, pitch: pitch)
                if let previous {
                    let start = CGPoint(x: center.x + previous.x * radius, y: center.y - previous.y * radius)
                    let end = CGPoint(x: center.x + point.x * radius, y: center.y - point.y * radius)
                    if previous.z + point.z >= 0 {
                        front.move(to: start)
                        front.addLine(to: end)
                    } else {
                        back.move(to: start)
                        back.addLine(to: end)
                    }
                }
                previous = point
            }
        }

        let meridianCount = min(max(meridians, 0), 90)
        for index in 0..<meridianCount {
            let longitude = 360 * Double(index) / Double(meridianCount)
            addLine(samples: 40) { (latitude: -90 + 180 * $0, longitude: longitude) }
        }

        let parallelCount = min(max(parallels, 0), 90)
        for index in 0..<parallelCount {
            let latitude = -90 + 180 * Double(index + 1) / Double(parallelCount + 1)
            addLine(samples: 72) { (latitude: latitude, longitude: 360 * $0) }
        }
        return (front, back)
    }
}

// MARK: - Demo

struct Globe3DWireframeDemo: View {
    private let cities = [
        Globe3DWireframePin(latitude: 40.4, longitude: -3.7),
        Globe3DWireframePin(latitude: 35.7, longitude: 139.7),
        Globe3DWireframePin(latitude: -33.9, longitude: 151.2),
        Globe3DWireframePin(latitude: 40.7, longitude: -74),
        Globe3DWireframePin(latitude: -23.5, longitude: -46.6),
        Globe3DWireframePin(latitude: -1.3, longitude: 36.8),
    ]

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(red: 0.05, green: 0.12, blue: 0.25), .black],
                center: .center,
                startRadius: 40,
                endRadius: 520
            )
            .ignoresSafeArea()

            Globe3DWireframe(pins: cities)
                .padding(24)

            VStack {
                Text("Drag to spin and tilt")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.top, 24)
                Spacer()
            }
        }
    }
}

#Preview {
    Globe3DWireframeDemo()
}
