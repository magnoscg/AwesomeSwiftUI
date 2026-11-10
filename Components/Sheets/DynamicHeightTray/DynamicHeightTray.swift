// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

nonisolated enum DynamicHeightTrayLogic {
    /// The height the tray takes for content that is `content` tall: never under `minimum` nor
    /// over `maximum`, and a whole number of points, so a measure that is off by a fraction
    /// does not start another round of layout.
    static func height(content: Double, minimum: Double = 80, maximum: Double) -> Double {
        guard content.isFinite, maximum.isFinite else { return minimum }
        return min(max(content.rounded(.up), minimum), max(maximum, minimum))
    }
}

extension View {
    /// Presents a sheet that is exactly as tall as its content, and that grows or shrinks with
    /// it when the content changes, as when one step of a flow gives way to the next.
    ///
    /// Change the content inside `withAnimation` and the tray follows it. The content is measured
    /// at the height it asks for, so give a list too long for the screen a frame of its own.
    func dynamicHeightTray<Tray: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Tray) -> some View {
        modifier(DynamicHeightTrayModifier(isPresented: isPresented, tray: content))
    }
}

private struct DynamicHeightTrayModifier<Tray: View>: ViewModifier {
    @Binding var isPresented: Bool
    @ViewBuilder var tray: () -> Tray

    /// The share of the screen the tray may take at most.
    private let maximumShare = 0.9

    @State private var detents: Set<PresentationDetent> = [.height(240)]
    @State private var detent = PresentationDetent.height(240)
    @State private var available: CGFloat = 800

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { available = $0 }
            .sheet(isPresented: $isPresented) {
                tray()
                    .fixedSize(horizontal: false, vertical: true)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { measured in
                        // A sheet animates from one detent to another, but not a detent that
                        // changes its height. So the new height joins the old one, the sheet
                        // moves to it, and the old one goes once it has arrived.
                        let fitted = PresentationDetent.height(DynamicHeightTrayLogic.height(content: measured, maximum: available * maximumShare))
                        detents.insert(fitted)
                        detent = fitted
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .presentationDetents(detents, selection: $detent)
                    .presentationDragIndicator(.visible)
                    .task(id: detent) {
                        try? await Task.sleep(for: .seconds(0.6))
                        if !Task.isCancelled { detents = [detent] }
                    }
            }
    }
}

// MARK: - Demo

struct DynamicHeightTrayDemo: View {
    private enum Step {
        case options, confirm, done
    }

    @State private var isPresented = false
    @State private var step = Step.options
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "wallet.bifold.fill")
                .font(.system(size: 52))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("Main Wallet")
                .font(.title2.bold())

            Button("Manage Wallet") {
                step = .options
                isPresented = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .dynamicHeightTray(isPresented: $isPresented) {
            VStack(alignment: .leading, spacing: 16) {
                switch step {
                case .options: options
                case .confirm: confirm
                case .done: done
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func go(to next: Step) {
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.35)) { step = next }
    }

    @ViewBuilder private var options: some View {
        Text("Manage Wallet")
            .font(.title3.bold())

        row("View Recovery Phrase", symbol: "key.fill") {}
        row("Rename Wallet", symbol: "pencil") {}
        row("Hide Small Balances", symbol: "eye.slash.fill") {}
        row("Remove Wallet", symbol: "trash.fill", role: .destructive) {
            go(to: .confirm)
        }
    }

    @ViewBuilder private var confirm: some View {
        Text("Remove this wallet?")
            .font(.title3.bold())
        Text("You will need its recovery phrase to add it again.")
            .font(.subheadline)
            .foregroundStyle(.secondary)

        HStack(spacing: 12) {
            Button("Cancel") {
                go(to: .options)
            }
            .buttonStyle(.bordered)

            Button("Remove", role: .destructive) {
                go(to: .done)
            }
            .buttonStyle(.borderedProminent)
        }
        .controlSize(.large)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var done: some View {
        Label("Wallet removed", systemImage: "checkmark.circle.fill")
            .font(.title3.bold())
            .foregroundStyle(.green)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
    }

    private func row(_ title: String, symbol: String, role: ButtonRole? = nil, action: @escaping () -> Void) -> some View {
        Button(role: role, action: action) {
            Label(title, systemImage: symbol)
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(.fill.quaternary, in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .foregroundStyle(role == .destructive ? AnyShapeStyle(.red) : AnyShapeStyle(.primary))
    }
}

#Preview {
    DynamicHeightTrayDemo()
}
