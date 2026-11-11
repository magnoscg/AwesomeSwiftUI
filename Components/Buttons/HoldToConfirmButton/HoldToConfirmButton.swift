// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A round button that only fires after being held while its ring fills.
/// Releasing early drains the ring and cancels.
///
/// With Reduce Motion on, the ring still fills, because it carries the meaning,
/// but the button does not squeeze. VoiceOver users confirm with a double tap.
struct HoldToConfirmButton: View {
    let title: String
    var systemImage: String = "checkmark"
    var tint: Color = .red
    var holdDuration: Double = 1.2
    let action: () -> Void

    @State private var progress = 0.0
    @State private var isConfirmed = false
    @State private var holdTask: Task<Void, Never>?
    @ScaledMetric(relativeTo: .title) private var diameter = 116.0
    @ScaledMetric(relativeTo: .title) private var ringWidth = 8.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isHolding: Bool { progress > 0 && !isConfirmed }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(tint.opacity(0.18), lineWidth: ringWidth)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(isConfirmed ? Color.green : tint, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Circle()
                    .fill((isConfirmed ? Color.green : tint).gradient)
                    .padding(ringWidth * 1.75)
                Image(systemName: isConfirmed ? "checkmark" : systemImage)
                    .font(.title.bold())
                    .foregroundStyle(HoldToConfirmButtonContrastingForeground(background: isConfirmed ? .green : tint))
                    .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
            }
            .frame(width: diameter, height: diameter)
            .scaleEffect(isHolding && !reduceMotion ? 0.92 : 1)
            .contentShape(.circle)
            // The gesture only reports pressing. The task below times the hold,
            // so the long minimum duration here never completes first.
            .onLongPressGesture(minimumDuration: 60, perform: {}, onPressingChanged: { isPressing in
                pressingChanged(isPressing)
            })

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .sensoryFeedback(.success, trigger: isConfirmed) { _, confirmed in confirmed }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to confirm")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { confirm() }
    }

    private func pressingChanged(_ isPressing: Bool) {
        guard !isConfirmed else { return }
        holdTask?.cancel()

        if isPressing {
            withAnimation(.linear(duration: holdDuration)) { progress = 1 }
            holdTask = Task {
                try? await Task.sleep(for: .seconds(holdDuration))
                guard !Task.isCancelled else { return }
                confirm()
            }
        } else {
            withAnimation(.easeOut(duration: 0.25)) { progress = 0 }
        }
    }

    private func confirm() {
        guard !isConfirmed else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            progress = 1
            isConfirmed = true
        }
        action()

        holdTask = Task {
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                progress = 0
                isConfirmed = false
            }
        }
    }
}

/// White or black, whichever reads better on `background`. Black only on a
/// light color, so the system's own colors keep white.
nonisolated struct HoldToConfirmButtonContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

struct HoldToConfirmButtonDemo: View {
    @State private var deleted = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HoldToConfirmButton(title: "Hold to delete", systemImage: "trash.fill") {
            deleted += 1
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) {
            VStack(spacing: 6) {
                Text(deleted, format: .number)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .contentTransition(reduceMotion ? .identity : .numericText(value: Double(deleted)))
                    .animation(reduceMotion ? nil : .snappy, value: deleted)
                Text("Files deleted")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .padding(.top, 72)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }
}

#Preview {
    HoldToConfirmButtonDemo()
}
