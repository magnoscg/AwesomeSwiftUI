// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A success badge: a circle springs in and the checkmark draws itself inside it.
///
/// With Reduce Motion on, the badge fades in and the checkmark does not draw.
struct AnimatedCheckmarkBadge: View {
    var isComplete: Bool
    var tint: Color = .green
    var size: CGFloat = 96
    var completeLabel = "Complete"
    var pendingLabel = "Pending"

    @ScaledMetric(relativeTo: .largeTitle) private var scale = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var circleAnimation: Animation {
        if reduceMotion { return .easeInOut(duration: 0.2) }
        return isComplete ? .spring(duration: 0.5, bounce: 0.5) : .easeOut(duration: 0.18)
    }

    private var checkAnimation: Animation? {
        if reduceMotion { return nil }
        return isComplete ? .easeOut(duration: 0.3).delay(0.16) : .easeOut(duration: 0.12)
    }

    var body: some View {
        let side = max(size, 0) * scale

        ZStack {
            Circle()
                .fill(tint.gradient)
                .scaleEffect(isComplete || reduceMotion ? 1 : 0.2)
                .opacity(isComplete ? 1 : 0)
                .animation(circleAnimation, value: isComplete)

            AnimatedCheckmarkBadgeCheck()
                .trim(from: 0, to: isComplete ? 1 : 0)
                .stroke(.white, style: StrokeStyle(lineWidth: side * 0.1, lineCap: .round, lineJoin: .round))
                .opacity(isComplete ? 1 : 0)
                .animation(checkAnimation, value: isComplete)
        }
        .frame(width: side, height: side)
        .sensoryFeedback(.success, trigger: isComplete) { _, isNowComplete in isNowComplete }
        .accessibilityElement()
        .accessibilityLabel(isComplete ? completeLabel : pendingLabel)
    }
}

nonisolated private struct AnimatedCheckmarkBadgeCheck: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY + rect.height * 0.53))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.44, y: rect.minY + rect.height * 0.68))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.73, y: rect.minY + rect.height * 0.35))
        return path
    }
}

// MARK: - Demo

struct AnimatedCheckmarkBadgeDemo: View {
    @State private var isDone = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [.mint.opacity(0.35), .teal.opacity(0.15)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                AnimatedCheckmarkBadge(isComplete: isDone, size: 120)
                    .background(Circle().fill(.quaternary))

                VStack(spacing: 6) {
                    Text(isDone ? "Payment sent" : "Review payment")
                        .font(.title2.bold())
                    Text(isDone ? "Your receipt is on its way." : "One tap and it is done.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)

                Button(isDone ? "Undo" : "Confirm") {
                    isDone.toggle()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(isDone ? .gray : .green)
            }
            .padding(32)
        }
    }
}

#Preview {
    AnimatedCheckmarkBadgeDemo()
}
