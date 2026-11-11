// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

nonisolated enum PasscodeKeypadLogic {
    static let rows = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

    /// `code` with one more digit, or as it was when it is already `length` long.
    static func adding(_ digit: Int, to code: String, length: Int) -> String {
        guard (0...9).contains(digit), code.count < length else { return code }
        return code + String(digit)
    }

    /// How far to the side the dots are while they shake: `progress` goes from 0 to 1, and the
    /// swings get shorter until the dots are back in place.
    static func shake(at progress: Double, amplitude: Double = 12, swings: Double = 3) -> Double {
        guard progress > 0, progress < 1 else { return 0 }
        return sin(progress * swings * 2 * .pi) * amplitude * (1 - progress)
    }
}

/// A number pad with a dot per digit, for a passcode kept in the app.
///
/// `onComplete` gets the code when its last digit is entered. Return `false` to reject it: the
/// dots turn red, shake and empty, with a haptic and a VoiceOver announcement. The digits are
/// never shown or read aloud. With Reduce Motion on, the dots turn red without shaking.
struct PasscodeKeypad: View {
    var title = "Enter Passcode"
    var length = 6
    var onComplete: (String) -> Bool

    private let rejectionSeconds = 0.5
    private let keySpacing: CGFloat = 20

    @State private var code = ""
    @State private var failures = 0
    @State private var isRejected = false
    @ScaledMetric(relativeTo: .title) private var keySize = 78.0
    @ScaledMetric(relativeTo: .title) private var dotSize = 14.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 32) {
            Text(title)
                .font(.title3.weight(.medium))

            dots

            keys
        }
        .sensoryFeedback(.selection, trigger: code)
        .sensoryFeedback(.error, trigger: failures)
        .task(id: failures) {
            guard failures > 0 else { return }
            try? await Task.sleep(for: .seconds(rejectionSeconds))
            code = ""
            isRejected = false
        }
    }

    private var dots: some View {
        HStack(spacing: dotSize) {
            ForEach(0..<max(length, 0), id: \.self) { index in
                Circle()
                    .fill(index < code.count ? AnyShapeStyle(isRejected ? .red : .primary) : AnyShapeStyle(.clear))
                    .strokeBorder(isRejected ? AnyShapeStyle(.red) : AnyShapeStyle(.primary), lineWidth: 1.5)
                    .frame(width: dotSize, height: dotSize)
            }
        }
        .keyframeAnimator(initialValue: 0.0, trigger: reduceMotion ? 0 : failures) { view, progress in
            view.offset(x: PasscodeKeypadLogic.shake(at: progress))
        } keyframes: { _ in
            LinearKeyframe(1, duration: rejectionSeconds)
        }
        .accessibilityElement()
        .accessibilityLabel(title)
        .accessibilityValue("\(code.count) of \(length) digits entered")
    }

    private var keys: some View {
        Grid(horizontalSpacing: keySpacing, verticalSpacing: keySpacing) {
            ForEach(PasscodeKeypadLogic.rows, id: \.self) { row in
                GridRow {
                    ForEach(row, id: \.self) { digit in
                        key(digit)
                    }
                }
            }
            GridRow {
                Color.clear
                    .gridCellUnsizedAxes([.horizontal, .vertical])
                key(0)
                Button {
                    code = String(code.dropLast())
                } label: {
                    Image(systemName: "delete.backward")
                        .font(.title2)
                        .frame(maxWidth: keySize, maxHeight: keySize)
                        .aspectRatio(1, contentMode: .fit)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .disabled(code.isEmpty || isRejected)
                .accessibilityLabel("Delete")
            }
        }
        // A number pad keeps 1, 2, 3 from left to right in every language, like a phone's.
        .environment(\.layoutDirection, .leftToRight)
    }

    private func key(_ digit: Int) -> some View {
        Button {
            press(digit)
        } label: {
            Text(verbatim: String(digit))
                .font(.system(.title, design: .rounded, weight: .medium))
                .minimumScaleFactor(0.5)
                .frame(maxWidth: keySize, maxHeight: keySize)
                .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(PasscodeKeypadKeyStyle())
    }

    private func press(_ digit: Int) {
        guard !isRejected, code.count < length else { return }
        code = PasscodeKeypadLogic.adding(digit, to: code, length: length)
        guard code.count == length, !onComplete(code) else { return }

        isRejected = true
        failures += 1
        AccessibilityNotification.Announcement("Wrong passcode").post()
    }
}

private struct PasscodeKeypadKeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? AnyShapeStyle(.fill) : AnyShapeStyle(.fill.tertiary), in: .circle)
            .contentShape(.circle)
            .animation(configuration.isPressed ? nil : .easeOut(duration: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Demo

struct PasscodeKeypadDemo: View {
    private let passcode = "2580"

    @State private var isUnlocked = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: isUnlocked ? "lock.open.fill" : "lock.fill")
                .font(.largeTitle)
                .foregroundStyle(isUnlocked ? .green : .secondary)
                .contentTransition(.symbolEffect(.replace))
                .accessibilityHidden(true)

            if isUnlocked {
                Text("Unlocked")
                    .font(.title2.bold())
                Button("Lock Again") {
                    isUnlocked = false
                }
                .buttonStyle(.bordered)
            } else {
                PasscodeKeypad(length: passcode.count) { code in
                    guard code == passcode else { return false }
                    Task {
                        try? await Task.sleep(for: .seconds(0.35))
                        isUnlocked = true
                    }
                    return true
                }

                Text("The passcode is \(passcode)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    PasscodeKeypadDemo()
}
