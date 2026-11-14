// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

struct PhotoMultiSelectGridPhoto: Identifiable {
    let id: String
    let image: Image
    let label: LocalizedStringResource
}

/// A photo grid where a long press enters a multi-select mode with checkmarks.
///
/// In that mode a tap toggles a photo. Out of it, a tap calls `onOpen`. Photos that disappear
/// also leave the selection. With Reduce Motion on, photos change state without animating.
struct PhotoMultiSelectGrid: View {
    let photos: [PhotoMultiSelectGridPhoto]
    @Binding var selection: Set<String>
    @Binding var isSelecting: Bool
    var onOpen: (PhotoMultiSelectGridPhoto) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animation: Animation? {
        reduceMotion ? nil : .snappy(duration: 0.25)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 4)], spacing: 4) {
                ForEach(photos) { photo in
                    cell(photo)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
        .onChange(of: photos.map(\.id)) { _, ids in
            selection.formIntersection(ids)
        }
    }

    private func cell(_ photo: PhotoMultiSelectGridPhoto) -> some View {
        let isChosen = selection.contains(photo.id)

        return Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                photo.image
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(.rect(cornerRadius: isChosen ? 14 : 0))
            .scaleEffect(isChosen ? 0.86 : 1)
            .overlay(alignment: .bottomTrailing) {
                if isSelecting {
                    checkmark(isChosen: isChosen)
                }
            }
            .contentShape(.rect)
            .onTapGesture { handleTap(photo) }
            .onLongPressGesture(minimumDuration: 0.35) { enterSelection(with: photo) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(photo.label)
            .accessibilityValue(isSelecting ? (isChosen ? "Selected" : "Not selected") : "")
            .accessibilityAddTraits(isChosen ? [.isButton, .isImage, .isSelected] : [.isButton, .isImage])
            .accessibilityAction { handleTap(photo) }
            .accessibilityActions {
                if !isSelecting {
                    Button("Select") { enterSelection(with: photo) }
                }
            }
    }

    private func checkmark(isChosen: Bool) -> some View {
        Image(systemName: isChosen ? "checkmark.circle.fill" : "circle")
            .font(.title2)
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, isChosen ? Color.accentColor : Color.black.opacity(0.25))
            .shadow(color: .black.opacity(0.3), radius: 3)
            .padding(8)
            .transition(.opacity)
    }

    private func handleTap(_ photo: PhotoMultiSelectGridPhoto) {
        guard isSelecting else {
            onOpen(photo)
            return
        }
        withAnimation(animation) {
            if selection.remove(photo.id) == nil {
                selection.insert(photo.id)
            }
        }
    }

    private func enterSelection(with photo: PhotoMultiSelectGridPhoto) {
        guard !isSelecting else { return }
        withAnimation(animation) {
            isSelecting = true
            selection.insert(photo.id)
        }
    }
}

// MARK: - Demo

struct PhotoMultiSelectGridDemo: View {
    @State private var selection: Set<String> = []
    @State private var isSelecting = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let photos = (1...15).map { number in
        PhotoMultiSelectGridPhoto(id: "\(number)", image: demoPhoto(number), label: "Photo \(number)")
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(isSelecting ? "\(selection.count) selected" : "Long press a photo")
                    .font(.title3.bold())
                    .monospacedDigit()
                Spacer()
                if isSelecting {
                    Button("Done") {
                        withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
                            isSelecting = false
                            selection = []
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(minHeight: 44)
            .padding(.horizontal, 16)

            PhotoMultiSelectGrid(photos: photos, selection: $selection, isSelecting: $isSelecting)
        }
    }
}

private func demoPhoto(_ number: Int) -> Image {
    let palettes: [[Color]] = [
        [.indigo, .pink], [.teal, .green], [.orange, .yellow], [.purple, .blue], [.red, .orange],
    ]
    let symbols = ["mountain.2.fill", "leaf.fill", "sun.max.fill", "moon.stars.fill", "flame.fill"]
    let colors = palettes[number % palettes.count]
    let symbol = symbols[number % symbols.count]
    let size = CGSize(width: 300, height: 300)

    return Image(size: size, label: Text("Photo \(number)")) { context in
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(Gradient(colors: colors), startPoint: .zero, endPoint: CGPoint(x: 300, y: 300))
        )
        var icon = context.resolve(Image(systemName: symbol))
        icon.shading = .color(.white.opacity(0.85))
        context.draw(icon, in: CGRect(x: 90, y: 90, width: 120, height: 120))
    }
}

#Preview {
    PhotoMultiSelectGridDemo()
}
