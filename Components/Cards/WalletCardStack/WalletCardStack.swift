// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

nonisolated enum WalletCardStackMath {
    /// The distance between the tops of two cards in the stack.
    ///
    /// It is `peek`, or less when the stack would not fit in `height`.
    static func step(count: Int, peek: Double, cardHeight: Double, height: Double) -> Double {
        guard count > 1, peek.isFinite, cardHeight.isFinite, height.isFinite else { return 0 }
        let room = max(height - cardHeight, 0)
        return min(max(peek, 0), room / Double(count - 1))
    }

    /// Where the top of each card goes.
    ///
    /// With no card open they sit one below another, `step` apart. With one open, it goes to the
    /// top and the others gather in a pile that keeps `pileHeight` at the bottom of `height`.
    static func tops(count: Int, selected: Int?, step: Double, height: Double, pileHeight: Double, pileStep: Double = 14) -> [Double] {
        guard count > 0 else { return [] }
        guard let selected, (0..<count).contains(selected) else {
            return (0..<count).map { Double($0) * step }
        }

        let others = count - 1
        let gap = others > 0 ? min(max(pileStep, 0), max(pileHeight, 0) / Double(others)) : 0
        var place = 0
        return (0..<count).map { index in
            guard index != selected else { return 0 }
            defer { place += 1 }
            return height - pileHeight + Double(place) * gap
        }
    }
}

/// A stack of cards, each one showing its top edge above the next. Tap a card and it rises to the
/// top with its details below, while the others wait in a pile at the bottom. Tap again to close.
///
/// Give it the height it can use: the stack tightens to fit, and the pile sits at the bottom edge.
/// With Reduce Motion on, the cards change places without sliding.
struct WalletCardStack<Item: Identifiable, Card: View, Detail: View>: View {
    let items: [Item]
    /// The card that is open, or `nil` when all of them are in the stack.
    @Binding var selection: Item.ID?
    var cardHeight: CGFloat = 200
    /// How much of a card shows above the next one in the stack. It grows with Dynamic Type.
    var peek: CGFloat = 64
    /// How much room the other cards keep at the bottom while one is open.
    var pileHeight: CGFloat = 76
    @ViewBuilder var card: (Item) -> Card
    @ViewBuilder var detail: (Item) -> Detail

    private let spacing: CGFloat = 16
    private let shadowRoom: CGFloat = 40

    @State private var height: CGFloat = 0
    @ScaledMetric(relativeTo: .headline) private var textScale = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let selected = items.firstIndex { $0.id == selection }
        let step = WalletCardStackMath.step(count: items.count, peek: peek * textScale, cardHeight: cardHeight, height: height)
        let tops = WalletCardStackMath.tops(count: items.count, selected: selected, step: step, height: height, pileHeight: pileHeight)

        ZStack(alignment: .top) {
            if let selected {
                detail(items[selected])
                    .frame(maxWidth: .infinity, alignment: .top)
                    .frame(height: max(height - cardHeight - pileHeight - spacing * 2, 0), alignment: .top)
                    .clipped()
                    .offset(y: cardHeight + spacing)
                    .transition(.opacity)
            }

            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                // In the stack only the top edge of a card is free, so that is where assistive touches land.
                let shown = selected == nil && index < items.count - 1 ? min(step, cardHeight) : cardHeight

                Button {
                    selection = selection == nil ? item.id : nil
                } label: {
                    card(item)
                        .frame(height: cardHeight)
                }
                .buttonStyle(WalletCardStackPressStyle())
                .offset(y: tops[index])
                .zIndex(Double(index + 1))
                .accessibilityActivationPoint(UnitPoint(x: 0.5, y: cardHeight > 0 ? shown / cardHeight / 2 : 0.5))
                .accessibilityAddTraits(index == selected ? .isSelected : [])
                .accessibilityHint(index == selected ? "Returns to the stack" : "Shows its details")
                .accessibilityHidden(selected != nil && index != selected)
                .accessibilitySortPriority(index == selected ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
        // Cuts the pile at the bottom edge and leaves room for the shadows of the cards everywhere else.
        .mask { Rectangle().padding(.horizontal, -shadowRoom).padding(.top, -shadowRoom) }
        .animation(reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.2), value: selection)
        .accessibilityAction(.escape) { selection = nil }
    }
}

private struct WalletCardStackPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Demo

private struct WalletCardStackDemoCard: Identifiable {
    let id: Int
    let name: String
    let digits: String
    let symbol: String
    let colors: [Color]
    let payments: [(place: String, symbol: String, amount: Double)]
}

struct WalletCardStackDemo: View {
    private let cards = [
        WalletCardStackDemoCard(id: 0, name: "Everyday", digits: "4821", symbol: "creditcard.fill", colors: [.indigo, .blue], payments: [
            ("Corner Bakery", "cup.and.saucer.fill", 6.4), ("Bookshop", "book.fill", 18.9), ("Groceries", "cart.fill", 52.3),
        ]),
        WalletCardStackDemoCard(id: 1, name: "Savings", digits: "0375", symbol: "leaf.fill", colors: [.teal, .green], payments: [
            ("Monthly transfer", "arrow.down.circle.fill", 250), ("Interest", "percent", 3.12), ("Round-ups", "plus.circle.fill", 14.75),
        ]),
        WalletCardStackDemoCard(id: 2, name: "Travel", digits: "9164", symbol: "airplane", colors: [.orange, .pink], payments: [
            ("Night train", "tram.fill", 74), ("Harbor Hotel", "bed.double.fill", 139.5), ("Museum", "building.columns.fill", 16),
        ]),
        WalletCardStackDemoCard(id: 3, name: "Transit", digits: "2208", symbol: "bus.fill", colors: [.purple, .indigo], payments: [
            ("Line 4", "bus.fill", 1.9), ("Top up", "plus.circle.fill", 20), ("Line 12", "bus.fill", 1.9),
        ]),
    ]

    @State private var selection: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Wallet")
                .font(.largeTitle.bold())

            WalletCardStack(items: cards, selection: $selection) { card in
                face(of: card)
            } detail: { card in
                payments(of: card)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .padding([.horizontal, .top], 20)
        .background(Color(.systemGroupedBackground))
    }

    private func face(of card: WalletCardStackDemoCard) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(card.name)
                    .font(.headline)
                Spacer()
                Image(systemName: card.symbol)
                    .font(.title3)
            }
            Spacer()
            Text("•••• \(card.digits)")
                .font(.title3.monospacedDigit())
        }
        .padding(20)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: card.colors, startPoint: .topLeading, endPoint: .bottomTrailing), in: .rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.3), radius: 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.name), ending in \(card.digits)")
    }

    private func payments(of card: WalletCardStackDemoCard) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Latest")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(card.payments, id: \.place) { payment in
                HStack(spacing: 12) {
                    Image(systemName: payment.symbol)
                        .frame(width: 32)
                        .foregroundStyle(card.colors[0])
                        .accessibilityHidden(true)
                    Text(payment.place)
                    Spacer()
                    Text(payment.amount, format: .currency(code: "USD"))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(16)
        .background(.background, in: .rect(cornerRadius: 16))
    }
}

#Preview {
    WalletCardStackDemo()
}
