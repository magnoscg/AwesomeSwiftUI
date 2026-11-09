// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

enum SwipeToConfirmSliderMath {
    /// How far along its travel the thumb is, from 0 to 1.
    static func progress(translation: Double, trackWidth: Double, thumbWidth: Double) -> Double {
        let travel = trackWidth - thumbWidth
        guard travel > 0 else { return 0 }
        return min(max(translation / travel, 0), 1)
    }

    static func thumbOffset(progress: Double, trackWidth: Double, thumbWidth: Double) -> Double {
        max(trackWidth - thumbWidth, 0) * min(max(progress, 0), 1)
    }

    static func isConfirmed(progress: Double, threshold: Double = 0.92) -> Bool {
        progress >= threshold
    }
}

/// A track with a thumb you drag to the end to confirm. Letting go early springs it back.
///
/// With Reduce Motion on, the thumb returns without bouncing. VoiceOver users
/// confirm with a double tap.
struct SwipeToConfirmSlider: View {
    let title: String
    var confirmedTitle: String = "Confirmed"
    var tint: Color = .indigo
    var resetDelay: Double = 1.4
    let onConfirm: () -> Void

    @State private var progress = 0.0
    @State private var isConfirmed = false
    @GestureState private var isDragging = false
    @ScaledMetric(relativeTo: .title3) private var height = 68.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let inset = 5.0

    private var settle: Animation {
        reduceMotion ? .easeOut(duration: 0.15) : .spring(duration: 0.45, bounce: 0.35)
    }

    var body: some View {
        GeometryReader { proxy in
            let trackWidth = proxy.size.width - inset * 2
            let thumbWidth = height - inset * 2
            let offset = SwipeToConfirmSliderMath.thumbOffset(
                progress: progress,
                trackWidth: trackWidth,
                thumbWidth: thumbWidth
            )

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)

                Capsule()
                    .fill(tint.gradient)
                    .frame(width: offset + height)

                Text(isConfirmed ? confirmedTitle : title)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(isConfirmed ? Color.white : Color.primary)
                    .opacity(isConfirmed ? 1 : max(1 - progress * 1.6, 0))
                    .padding(.horizontal, height)
                    .frame(maxWidth: .infinity)

                Image(systemName: isConfirmed ? "checkmark" : "chevron.right.2")
                    .font(.title3.bold())
                    .foregroundStyle(tint)
                    .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
                    .frame(width: thumbWidth, height: thumbWidth)
                    .background(.white, in: .circle)
                    .shadow(color: .black.opacity(0.2), radius: 5, y: 3)
                    .contentShape(.circle)
                    .offset(x: inset + offset)
                    .gesture(drag(trackWidth: trackWidth, thumbWidth: thumbWidth))
            }
        }
        .frame(height: height)
        .onChange(of: isDragging) { _, dragging in
            guard !dragging, !isConfirmed else { return }
            withAnimation(settle) { progress = 0 }
        }
        .sensoryFeedback(.success, trigger: isConfirmed) { _, confirmed in confirmed }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isConfirmed ? confirmedTitle : title)
        .accessibilityHint("Double tap to confirm")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { confirm() }
    }

    private func drag(trackWidth: Double, thumbWidth: Double) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { value in
                guard !isConfirmed else { return }
                progress = SwipeToConfirmSliderMath.progress(
                    translation: value.translation.width,
                    trackWidth: trackWidth,
                    thumbWidth: thumbWidth
                )
            }
            .onEnded { _ in
                if SwipeToConfirmSliderMath.isConfirmed(progress: progress) {
                    confirm()
                }
            }
    }

    private func confirm() {
        guard !isConfirmed else { return }
        withAnimation(settle) {
            progress = 1
            isConfirmed = true
        }
        onConfirm()

        Task {
            try? await Task.sleep(for: .seconds(resetDelay))
            withAnimation(settle) {
                progress = 0
                isConfirmed = false
            }
        }
    }
}

// MARK: - Demo

struct SwipeToConfirmSliderDemo: View {
    @State private var payments = 0

    var body: some View {
        SwipeToConfirmSlider(title: "Slide to pay") {
            payments += 1
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) {
            VStack(spacing: 6) {
                Text("48.00 €")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text(payments == 1 ? "1 payment sent" : "\(payments) payments sent")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 72)
        }
    }
}

#Preview {
    SwipeToConfirmSliderDemo()
}
