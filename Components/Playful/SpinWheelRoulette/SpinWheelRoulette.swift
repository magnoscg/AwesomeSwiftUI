// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A prize wheel that spins with friction and lands on a random slice.
///
/// With Reduce Motion on, the wheel moves straight to the result.
struct SpinWheelRoulette: View {
    let slices: [String]
    var onResult: (String) -> Void = { _ in }

    @State private var rotation = 0.0
    @State private var isSpinning = false
    @State private var lastResult: String?
    @State private var finishedSpins = 0
    @State private var lastSpinSlices: [String]?

    @ScaledMetric(relativeTo: .headline) private var hubSize: CGFloat = 78
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let palette: [Color] = [.pink, .orange, .yellow, .green, .teal, .blue, .indigo, .purple]

    /// The wheel keeps the slices of the last spin until the next one, so the result always matches it.
    private var drawnSlices: [String] { lastSpinSlices ?? slices }

    var body: some View {
        ZStack {
            wheel
                .rotationEffect(.degrees(rotation))
                .accessibilityElement()
                .accessibilityLabel("Prize wheel")
                .accessibilityValue(drawnSlices.joined(separator: ", "))

            Circle()
                .strokeBorder(.white.opacity(0.9), lineWidth: 6)
                .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
                .accessibilityHidden(true)

            VStack {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
                    .offset(y: -16)
                Spacer()
            }
            .accessibilityHidden(true)

            Button(action: spin) {
                Text("Spin")
                    .font(.headline.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(.white)
                    .padding(8)
                    .frame(width: hubSize, height: hubSize)
                    .background(.black.gradient, in: .circle)
                    .overlay { Circle().strokeBorder(.white, lineWidth: 3) }
            }
            .buttonStyle(.plain)
            .disabled(isSpinning || slices.isEmpty)
            .accessibilityValue(lastResult ?? "")
        }
        .aspectRatio(1, contentMode: .fit)
        .sensoryFeedback(.success, trigger: finishedSpins)
    }

    private var wheel: some View {
        Canvas { [drawnSlices] context, size in
            let radius = min(size.width, size.height) / 2
            guard radius > 0, !drawnSlices.isEmpty else { return }

            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let slice = SpinWheelRouletteMath.sliceAngle(count: drawnSlices.count)

            for (index, label) in drawnSlices.enumerated() {
                let start = Double(index) * slice - 90
                var wedge = Path()
                if drawnSlices.count == 1 {
                    wedge.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
                } else {
                    wedge.move(to: center)
                    wedge.addArc(center: center, radius: radius, startAngle: .degrees(start), endAngle: .degrees(start + slice), clockwise: false)
                    wedge.closeSubpath()
                }
                context.fill(wedge, with: .color(palette[index % palette.count].opacity(0.92)))
                context.stroke(wedge, with: .color(.white.opacity(0.75)), lineWidth: 1.5)

                var labelContext = context
                labelContext.translateBy(x: center.x, y: center.y)
                labelContext.rotate(by: .degrees(start + slice / 2))
                labelContext.draw(
                    Text(label).font(.subheadline.weight(.bold)).foregroundStyle(.white),
                    in: CGRect(x: radius * 0.34, y: -radius * 0.1, width: radius * 0.62, height: radius * 0.2)
                )
            }
        }
        .clipShape(.circle)
    }

    private func spin() {
        guard !isSpinning, !slices.isEmpty else { return }

        let winner = Int.random(in: slices.indices)
        let label = slices[winner]
        let target = SpinWheelRouletteMath.targetRotation(
            from: rotation,
            winner: winner,
            count: slices.count,
            jitter: .random(in: -0.35...0.35)
        )
        isSpinning = true
        lastSpinSlices = slices

        if reduceMotion {
            rotation = target
            finish(with: label)
        } else {
            withAnimation(.timingCurve(0.12, 0.75, 0.12, 1, duration: 3.2), completionCriteria: .removed) {
                rotation = target
            } completion: {
                finish(with: label)
            }
        }
    }

    private func finish(with label: String) {
        isSpinning = false
        lastResult = label
        finishedSpins += 1
        AccessibilityNotification.Announcement("Landed on \(label)").post()
        onResult(label)
    }
}

enum SpinWheelRouletteMath {
    static func sliceAngle(count: Int) -> Double {
        count > 0 ? 360 / Double(count) : 360
    }

    /// The rotation that brings `winner` under the pointer after `turns` whole turns, always moving forward.
    /// `jitter` moves the landing point inside the slice, as a fraction of it.
    static func targetRotation(from current: Double, winner: Int, count: Int, turns: Int = 5, jitter: Double = 0) -> Double {
        let resting = -(Double(winner) + 0.5 + jitter) * sliceAngle(count: count)
        return current + Double(max(turns, 0)) * 360 + normalized(resting - current)
    }

    /// The slice under the pointer at the top of the wheel for a rotation in degrees.
    static func winner(rotation: Double, count: Int) -> Int? {
        guard count > 0, rotation.isFinite else { return nil }
        return min(Int(normalized(-rotation) / sliceAngle(count: count)), count - 1)
    }

    private static func normalized(_ degrees: Double) -> Double {
        let remainder = degrees.truncatingRemainder(dividingBy: 360)
        return remainder < 0 ? remainder + 360 : remainder
    }
}

// MARK: - Demo

struct SpinWheelRouletteDemo: View {
    @State private var result: String?

    private let slices = ["10% off", "Free tea", "Retry", "Gift", "25% off", "Bonus", "Sticker", "Jackpot"]

    var body: some View {
        VStack(spacing: 28) {
            Text("Spin to Win")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            SpinWheelRoulette(slices: slices) { result = $0 }
                .padding(.horizontal, 24)

            Text(result.map { "You got: \($0)" } ?? "Tap the wheel to try your luck")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [.indigo, .black], startPoint: .top, endPoint: .bottom))
    }
}

#Preview {
    SpinWheelRouletteDemo()
}
