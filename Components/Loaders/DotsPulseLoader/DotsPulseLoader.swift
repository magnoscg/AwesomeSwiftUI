// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// Dots that pulse one after the other.
///
/// With Reduce Motion on, the dots stay still.
struct DotsPulseLoader: View {
    var color: Color = .indigo
    var dotCount: Int = 3
    var dotSize: CGFloat = 14

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                dots(activeIndex: nil)
            } else {
                PhaseAnimator(Array(0..<max(dotCount, 1))) { index in
                    dots(activeIndex: index)
                } animation: { _ in
                    .easeInOut(duration: 0.32)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Loading")
    }

    private func dots(activeIndex: Int?) -> some View {
        HStack(spacing: dotSize * 0.6) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(color.gradient)
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(scale(index: index, activeIndex: activeIndex))
                    .opacity(index == activeIndex || activeIndex == nil ? 1 : 0.4)
            }
        }
    }

    private func scale(index: Int, activeIndex: Int?) -> CGFloat {
        guard let activeIndex else { return 0.85 }
        return index == activeIndex ? 1.15 : 0.7
    }
}

// MARK: - Demo

struct DotsPulseLoaderDemo: View {
    var body: some View {
        VStack(spacing: 48) {
            DotsPulseLoader(color: .indigo, dotSize: 44)

            VStack(alignment: .leading, spacing: 10) {
                Text("Did the package arrive?")
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.blue.gradient, in: .rect(cornerRadius: 20))
                    .frame(maxWidth: .infinity, alignment: .trailing)

                DotsPulseLoader(color: .secondary, dotSize: 10)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 20))
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    DotsPulseLoaderDemo()
}
