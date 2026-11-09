// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A radio button whose dot springs in and whose ring pulses once when selected.
///
/// With Reduce Motion on, the dot appears at once and there is no pulse.
struct AnimatedRadioButton: View {
    let title: String
    let isSelected: Bool
    var tint: Color = .indigo
    let action: () -> Void

    @ScaledMetric(relativeTo: .body) private var size = 26.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                indicator

                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var indicator: some View {
        ZStack {
            Circle()
                .strokeBorder(isSelected ? tint : Color.secondary, lineWidth: 2)

            Circle()
                .fill(tint)
                .padding(size * 0.22)
                .scaleEffect(isSelected ? 1 : 0.01)
                .opacity(isSelected ? 1 : 0)
        }
        .frame(width: size, height: size)
        .background {
            Circle()
                .stroke(tint, lineWidth: 2)
                .keyframeAnimator(initialValue: 0.0, trigger: isSelected) { [reduceMotion] ring, progress in
                    let isPulsing = isSelected && !reduceMotion && progress > 0 && progress < 1

                    ring
                        .scaleEffect(1 + progress * 0.9)
                        .opacity(isPulsing ? 1 - progress : 0)
                } keyframes: { _ in
                    // Each run starts from the last value, so the ring has to jump back.
                    MoveKeyframe(0)
                    CubicKeyframe(1, duration: 0.5)
                }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.35, bounce: 0.55), value: isSelected)
        .accessibilityHidden(true)
    }
}

// MARK: - Demo

struct AnimatedRadioButtonDemo: View {
    private let options = ["Standard delivery", "Express delivery", "Pick up in store"]

    @State private var selection = 0
    @State private var isAutoPlaying = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("How should we send it?")
                    .font(.system(.title, design: .rounded, weight: .bold))

                VStack(spacing: 22) {
                    ForEach(options.indices, id: \.self) { index in
                        AnimatedRadioButton(title: options[index], isSelected: selection == index) {
                            isAutoPlaying = false
                            selection = index
                        }
                    }
                }
                .padding(24)
                .background(.regularMaterial, in: .rect(cornerRadius: 28))
            }
            .padding(24)
        }
        .defaultScrollAnchor(.center, for: .alignment)
        .background(
            LinearGradient(colors: [.indigo.opacity(0.2), .mint.opacity(0.14)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }

            while isAutoPlaying {
                try? await Task.sleep(for: .seconds(1.1))
                guard !Task.isCancelled, isAutoPlaying else { return }
                selection = (selection + 1) % options.count
            }
        }
    }
}

#Preview {
    AnimatedRadioButtonDemo()
}
