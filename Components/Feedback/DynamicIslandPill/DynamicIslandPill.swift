// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A black capsule that grows to show a live status and shrinks back to a pill.
///
/// Place it at the top of the screen. With Reduce Motion on, it changes size
/// without bouncing and its content only fades.
struct DynamicIslandPill<Content: View>: View {
    var isExpanded: Bool
    var pillSize = CGSize(width: 126, height: 37)
    var expandedCornerRadius: CGFloat = 36
    @ViewBuilder var content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var width: CGFloat { max(pillSize.width, 0) }
    private var height: CGFloat { max(pillSize.height, 0) }

    var body: some View {
        let shape = RoundedRectangle(
            cornerRadius: isExpanded ? expandedCornerRadius : height / 2,
            style: .continuous
        )

        ZStack {
            if isExpanded {
                content()
                    .foregroundStyle(.white)
                    .environment(\.colorScheme, .dark)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 18)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.8, anchor: .top)))
            }
        }
        .frame(width: isExpanded ? nil : width, height: isExpanded ? nil : height)
        .background(.black, in: shape)
        .clipShape(shape)
        .padding(.horizontal, isExpanded ? 10 : 0)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.5, bounce: 0.3), value: isExpanded)
        .accessibilityElement(children: .contain)
        .accessibilityHidden(!isExpanded)
    }
}

// MARK: - Demo

private enum DynamicIslandPillDemoStatus {
    case music
    case timer
}

struct DynamicIslandPillDemo: View {
    @State private var status: DynamicIslandPillDemoStatus?
    @State private var timerEnd = Date.now
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [.purple, .indigo, .blue], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            DynamicIslandPill(isExpanded: status != nil) {
                switch status {
                case .music: musicStatus
                case .timer: timerStatus
                case nil: EmptyView()
                }
            }
            .animation(reduceMotion ? nil : .snappy, value: status)
            .padding(.top, 11)
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 14) {
                Button("Music") { status = .music }
                Button("Timer") {
                    timerEnd = .now + 25 * 60
                    status = .timer
                }
                Button("Collapse") { status = nil }
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.25))
            .controlSize(.large)
            .frame(maxHeight: .infinity)
        }
    }

    private var musicStatus: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(colors: [.pink, .orange], startPoint: .top, endPoint: .bottom))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "music.note")
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Midnight City")
                    .font(.headline)
                Text("Now playing")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "waveform")
                .font(.title2)
                .foregroundStyle(.pink)
                .symbolEffect(.variableColor.iterative, options: .repeating, isActive: !reduceMotion)
                .accessibilityHidden(true)
        }
    }

    private var timerStatus: some View {
        HStack(spacing: 14) {
            Image(systemName: "timer")
                .font(.title)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            Text("Focus session")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(timerEnd, style: .timer)
                .font(.title2.bold())
                .monospacedDigit()
                .foregroundStyle(.orange)
        }
    }
}

#Preview {
    DynamicIslandPillDemo()
}
