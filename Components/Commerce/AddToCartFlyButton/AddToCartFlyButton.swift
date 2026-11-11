// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A product image and an add button that sends a copy of the image arcing into the cart.
///
/// Measure your cart icon in the `.global` space and pass its frame as `cartFrame`. The
/// count goes up when the copy lands. With Reduce Motion on, or with no `cartFrame`, the
/// count goes up at once and nothing flies.
struct AddToCartFlyButton: View {
    let image: Image
    @Binding var count: Int
    var cartFrame: CGRect?
    var title: String = "Add to Cart"
    var imageLabel: String = "Product"
    var tint: Color = .indigo
    var onAdd: () -> Void = {}

    @State private var flights: [AddToCartFlyButtonLaunch] = []
    @State private var sourceFrame = CGRect.zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let maximumFlights = 6

    var body: some View {
        VStack(spacing: 20) {
            image
                .resizable()
                .scaledToFit()
                .foregroundStyle(tint)
                .padding(36)
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .background(tint.opacity(0.12), in: .rect(cornerRadius: 28))
                .accessibilityLabel(imageLabel)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { sourceFrame = $0 }
                .overlay {
                    ForEach(flights) { flight in
                        AddToCartFlyButtonFlight(image: image, destination: flight.destination, tint: tint) {
                            land(flight.id)
                        }
                    }
                }

            Button(action: add) {
                Label(title, systemImage: "cart.badge.plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(tint)
        }
    }

    private func add() {
        guard !reduceMotion, flights.count < maximumFlights, let cartFrame, sourceFrame != .zero else {
            increment()
            return
        }
        let destination = CGSize(width: cartFrame.midX - sourceFrame.midX, height: cartFrame.midY - sourceFrame.midY)
        flights.append(AddToCartFlyButtonLaunch(destination: destination))
    }

    private func land(_ id: UUID) {
        guard let index = flights.firstIndex(where: { $0.id == id }) else { return }
        flights.remove(at: index)
        increment()
    }

    private func increment() {
        count = count == .max ? count : count + 1
        onAdd()
    }
}

private struct AddToCartFlyButtonLaunch: Identifiable {
    let id = UUID()
    let destination: CGSize
}

/// The flying copy. It lands even if its view goes away mid-flight, so no item is lost.
private struct AddToCartFlyButtonFlight: View {
    let image: Image
    let destination: CGSize
    let tint: Color
    let onLand: () -> Void

    @State private var progress = 0.0

    private let duration = 0.65

    var body: some View {
        image
            .resizable()
            .scaledToFit()
            .foregroundStyle(tint)
            .padding(14)
            .frame(width: 84, height: 84)
            .background(.background, in: .circle)
            .overlay { Circle().strokeBorder(tint.opacity(0.3)) }
            .modifier(AddToCartFlyButtonArc(progress: progress, destination: destination))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .task {
                withAnimation(.easeIn(duration: duration)) { progress = 1 }
                try? await Task.sleep(for: .seconds(duration))
                onLand()
            }
    }
}

/// Moves a view along the arc and shrinks it as it travels.
private struct AddToCartFlyButtonArc: GeometryEffect {
    var progress: Double
    let destination: CGSize

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = AddToCartFlyButtonLogic.arcOffset(progress: progress, destination: destination, lift: 120)
        let scale = 1 - 0.75 * CGFloat(min(max(progress, 0), 1))
        let transform = CGAffineTransform(translationX: offset.width + size.width / 2, y: offset.height + size.height / 2)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -size.width / 2, y: -size.height / 2)
        return ProjectionTransform(transform)
    }
}

enum AddToCartFlyButtonLogic {
    /// A point on a curve from zero to `destination` that first rises by about `lift`.
    static func arcOffset(progress: Double, destination: CGSize, lift: CGFloat) -> CGSize {
        let t = CGFloat(min(max(progress, 0), 1))
        let controlX = destination.width * 0.35
        let controlY = min(destination.height, 0) - lift
        return CGSize(
            width: 2 * (1 - t) * t * controlX + t * t * destination.width,
            height: 2 * (1 - t) * t * controlY + t * t * destination.height
        )
    }
}

/// A cart icon with a count badge that bumps when the count changes.
struct AddToCartFlyButtonCart: View {
    let count: Int
    var tint: Color = .indigo

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image(systemName: "cart.fill")
            .font(.title2)
            .foregroundStyle(tint)
            .padding(8)
            .overlay(alignment: .topTrailing) {
                if count > 0 {
                    Text(count, format: .number)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .contentTransition(reduceMotion ? .identity : .numericText(value: Double(count)))
                        .animation(reduceMotion ? nil : .snappy, value: count)
                        .padding(.horizontal, 5)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(.red, in: .capsule)
                }
            }
            .keyframeAnimator(initialValue: 1.0, trigger: reduceMotion ? 0 : count) { [reduceMotion] view, scale in
                view.scaleEffect(reduceMotion ? 1 : scale)
            } keyframes: { _ in
                SpringKeyframe(1.3, duration: 0.14)
                SpringKeyframe(1, duration: 0.3)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Cart")
            .accessibilityValue(count == 1 ? "1 item" : "\(count) items")
    }
}

// MARK: - Demo

struct AddToCartFlyButtonDemo: View {
    @State private var count = 0
    @State private var cartFrame: CGRect?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Shop")
                    .font(.largeTitle.bold())
                Spacer()
                AddToCartFlyButtonCart(count: count)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { cartFrame = $0 }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    AddToCartFlyButton(
                        image: Image(systemName: "backpack.fill"),
                        count: $count,
                        cartFrame: cartFrame,
                        imageLabel: "Trail backpack"
                    )
                    .padding(.top, 48)

                    Text("Trail backpack")
                        .font(.title2.bold())
                        .padding(.top, 12)
                    Text("Twenty liters, water resistant and light enough for every day.")
                        .foregroundStyle(.secondary)
                }
                .padding(24)
            }
            .scrollClipDisabled()
        }
    }
}

#Preview {
    AddToCartFlyButtonDemo()
}
