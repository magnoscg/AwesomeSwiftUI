// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

nonisolated enum SlotMachineReelsMath {
    /// The symbol under the line when a reel has turned `position` rows.
    static func index(at position: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return ((position % count) + count) % count
    }

    /// Where a reel stops: `turns` whole turns further on, and then on to `target`.
    static func stop(from position: Int, on target: Int, count: Int, turns: Int) -> Int {
        guard count > 0 else { return position }
        let ahead = index(at: target - index(at: position, count: count), count: count)
        return position + max(turns, 0) * count + ahead
    }

    /// A win is every reel on the same symbol.
    static func isWin(_ result: [Int]) -> Bool {
        guard let first = result.first, result.count > 1 else { return false }
        return result.allSatisfy { $0 == first }
    }
}

/// Reels that spin and stop one after another, each a little later than the one before.
///
/// `onResult` gets the symbols under the line once the last reel stops. With Reduce Motion
/// on, the reels change to their result without spinning.
struct SlotMachineReels: View {
    let symbols: [String]
    var reelCount = 3
    var spinTitle: LocalizedStringResource = "Spin"
    var tint: Color = .red
    var onResult: ([String]) -> Void = { _ in }

    @State private var positions: [Int] = []
    @State private var isSpinning = false
    @State private var stops = 0
    @ScaledMetric(relativeTo: .largeTitle) private var cell = 78.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let firstStop = 1.3
    private let stagger = 0.45

    private var reels: Int { max(reelCount, 1) }

    private func position(of reel: Int) -> Int {
        positions.indices.contains(reel) ? positions[reel] : 0
    }

    private var result: [String] {
        guard !symbols.isEmpty else { return [] }
        return (0..<reels).map { symbols[SlotMachineReelsMath.index(at: position(of: $0), count: symbols.count)] }
    }

    var body: some View {
        VStack(spacing: 22) {
            HStack(spacing: 10) {
                ForEach(0..<reels, id: \.self) { reel in
                    SlotMachineReelsStrip(position: Double(position(of: reel)), symbols: symbols, cell: cell)
                        .frame(maxWidth: .infinity)
                        .frame(height: cell * 2.2)
                        .background(.white, in: .rect(cornerRadius: 16))
                        .overlay {
                            // Light from above and below, so the symbols seem to turn on a drum.
                            LinearGradient(colors: [.black.opacity(0.28), .clear, .clear, .black.opacity(0.28)], startPoint: .top, endPoint: .bottom)
                                .clipShape(.rect(cornerRadius: 16))
                                .allowsHitTesting(false)
                        }
                }
            }
            .padding(12)
            .background(tint.gradient, in: .rect(cornerRadius: 26))
            .overlay {
                Capsule()
                    .fill(SlotMachineReelsContrastingForeground(background: tint))
                    .frame(height: 3)
                    .padding(.horizontal, 4)
                    .opacity(0.9)
                    .allowsHitTesting(false)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Reels")
            .accessibilityValue(isSpinning ? Text("Spinning") : Text(verbatim: result.joined(separator: ", ")))

            Button(action: spin) {
                Text(spinTitle)
                    .font(.title3.bold())
                    .foregroundStyle(SlotMachineReelsContrastingForeground(background: tint))
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(tint.gradient, in: .capsule)
                    .opacity(isSpinning ? 0.5 : 1)
            }
            .buttonStyle(.plain)
            .disabled(isSpinning || symbols.isEmpty)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: stops)
    }

    private func spin() {
        guard !isSpinning, !symbols.isEmpty else { return }
        isSpinning = true
        if positions.count != reels { positions = (0..<reels).map(position(of:)) }

        for reel in 0..<reels {
            let target = Int.random(in: symbols.indices)
            let next = SlotMachineReelsMath.stop(from: positions[reel], on: target, count: symbols.count, turns: 3 + reel)
            let isLast = reel == reels - 1

            withAnimation(reduceMotion ? nil : .timingCurve(0.2, 0.75, 0.25, 1, duration: firstStop + stagger * Double(reel))) {
                positions[reel] = next
            } completion: {
                stops += 1
                guard isLast else { return }
                isSpinning = false
                onResult(result)
            }
        }
    }
}

/// One reel. `Animatable` redraws it for every frame of a spin, so the symbols travel past the line.
private struct SlotMachineReelsStrip: View, Animatable {
    var position: Double
    let symbols: [String]
    let cell: CGFloat

    nonisolated var animatableData: Double {
        get { position }
        set { position = newValue }
    }

    var body: some View {
        let base = Int(position.rounded(.down))
        let fraction = position - Double(base)

        ZStack {
            if !symbols.isEmpty {
                ForEach(-2...2, id: \.self) { row in
                    Text(verbatim: symbols[SlotMachineReelsMath.index(at: base + row, count: symbols.count)])
                        .font(.system(size: cell * 0.56))
                        .frame(height: cell)
                        .offset(y: (fraction - Double(row)) * cell)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

/// White or black, whichever reads better on `background`. Black only on a
/// light color, so the system's own colors keep white.
nonisolated struct SlotMachineReelsContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

struct SlotMachineReelsDemo: View {
    private let symbols = ["🍒", "🍋", "🔔", "⭐️", "💎", "🍀"]

    @State private var message: LocalizedStringResource = "Pull your luck"
    @State private var spins = 0

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 6) {
                Text("Lucky Reels")
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                Text(message)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .contentTransition(.opacity)
            }

            SlotMachineReels(symbols: symbols, tint: .yellow) { result in
                spins += 1
                message = Set(result).count == 1 ? "Three of a kind!" : (Set(result).count == 2 ? "So close" : "Try again")
            }

            Text("^[\(spins) spin](inflect: true)")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.6))
        }
        .foregroundStyle(.white)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [Color(red: 0.36, green: 0.05, blue: 0.2), Color(red: 0.1, green: 0.02, blue: 0.12)], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .animation(.easeInOut(duration: 0.25), value: spins)
    }
}

#Preview {
    SlotMachineReelsDemo()
}
