// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A field whose list of options grows out of it and collapses on selection.
///
/// The list floats over the views below, so use it in a stack where it can overlap
/// them. It raises itself with `zIndex` while open, and a tap outside closes it.
struct DropdownSelectMenu<Option: Hashable>: View {
    let title: LocalizedStringResource
    let options: [Option]
    @Binding var selection: Option?
    var placeholder = "Choose"
    let label: (Option) -> String

    @State private var isOpen = false
    @State private var fieldHeight: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animation: Animation? { reduceMotion ? nil : .smooth(duration: 0.28) }
    private let cornerRadius: CGFloat = 14
    private let contentPadding: CGFloat = 14
    private let maxListHeight: CGFloat = 280

    private var listTop: CGFloat { fieldHeight + 6 }
    /// The top edge of the list, as a point of the padded box the transition scales.
    private var listAnchor: UnitPoint { UnitPoint(x: 0.5, y: listTop / (listTop + maxListHeight)) }

    var body: some View {
        field
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fieldHeight = $0 }
            .overlay(alignment: .top) {
                if isOpen {
                    // An overlay is offered the size of the field, which would squeeze the list
                    // into one row. This offers it its own height, and starts it under the field.
                    optionsList
                        .frame(height: maxListHeight, alignment: .top)
                        .padding(.top, listTop)
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.9, anchor: listAnchor).combined(with: .opacity))
                }
            }
            .background {
                if isOpen {
                    Color.clear
                        .frame(width: 4000, height: 4000)
                        .contentShape(.rect)
                        .onTapGesture { setOpen(false) }
                        .accessibilityHidden(true)
                }
            }
            .zIndex(isOpen ? 1 : 0)
    }

    private var field: some View {
        Button {
            setOpen(!isOpen)
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.caption).foregroundStyle(.secondary)
                    Text(selection.map(label) ?? placeholder)
                        .font(.body)
                        .foregroundStyle(selection == nil ? .secondary : .primary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.down")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isOpen ? 180 : 0))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, contentPadding)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: .rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(.separator)
            }
            .contentShape(.rect(cornerRadius: cornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(selection.map(label) ?? placeholder)
        .accessibilityHint(isOpen ? "Closes the list" : "Opens the list")
    }

    private var optionsList: some View {
        ViewThatFits(in: .vertical) {
            optionStack
            ScrollView { optionStack }
        }
        .background(.regularMaterial, in: .rect(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(.separator)
        }
        .clipShape(.rect(cornerRadius: cornerRadius))
        .shadow(color: .black.opacity(0.14), radius: 14, y: 6)
    }

    private var optionStack: some View {
        VStack(spacing: 0) {
            if options.isEmpty {
                Text("No options")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(contentPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                    setOpen(false)
                } label: {
                    HStack {
                        Text(label(option)).font(.body)
                        Spacer(minLength: 8)
                        if option == selection {
                            Image(systemName: "checkmark")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.tint)
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.horizontal, contentPadding)
                    .frame(minHeight: 46)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(option == selection ? .isSelected : [])
            }
        }
    }

    private func setOpen(_ open: Bool) {
        withAnimation(animation) { isOpen = open }
    }
}

// MARK: - Demo

struct DropdownSelectMenuDemo: View {
    @State private var shipping: String? = "Standard"
    @State private var country: String?
    @State private var notes = "Tap a field to open it"

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.18), .purple.opacity(0.18)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("Checkout").font(.largeTitle.bold())

                DropdownSelectMenu(
                    title: "Shipping",
                    options: ["Standard", "Express", "Overnight", "Pickup"],
                    selection: $shipping,
                    label: { $0 }
                )

                DropdownSelectMenu(
                    title: "Country",
                    options: ["France", "Italy", "Portugal", "Spain"],
                    selection: $country,
                    placeholder: "Select a country",
                    label: { $0 }
                )

                Text(notes)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(20)
        }
        .onChange(of: shipping) { _, new in notes = "Delivery: \(new ?? "none")" }
    }
}

#Preview {
    DropdownSelectMenuDemo()
}
