// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import MapKit
import SwiftUI

nonisolated struct MapSearchSheetPlace: Identifiable, Hashable, Sendable {
    var id: String
    var name: String
    var kind: String
    var symbol: String
    var latitude: Double
    var longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

nonisolated enum MapSearchSheetLogic {
    /// The places whose name or kind has every word of `query`, whatever its case and accents.
    /// An empty query keeps them all.
    static func matches(_ places: [MapSearchSheetPlace], query: String) -> [MapSearchSheetPlace] {
        let words = folded(query).split(separator: " ")
        guard !words.isEmpty else { return places }
        return places.filter { place in
            let text = folded("\(place.name) \(place.kind)")
            return words.allSatisfy { text.contains($0) }
        }
    }

    private static func folded(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}

/// A map with a sheet of places that never goes away, like the one in Maps: it rests at the
/// bottom, at half height or full, and the map stays usable behind it.
///
/// Typing filters the list and the markers. Choosing a place, in the list or on the map, flies
/// the camera to it. The places are yours: fill them from `MKLocalSearch` or from your own data.
struct MapSearchSheet: View {
    let places: [MapSearchSheetPlace]
    var prompt = "Search places"
    /// How far above a chosen place the camera stops, in meters.
    var closeUpDistance = 1500.0

    private static let restingHeight: CGFloat = 76
    private static let resting = PresentationDetent.height(restingHeight)

    @State private var position = MapCameraPosition.automatic
    @State private var selection: MapSearchSheetPlace.ID?
    @State private var query = ""
    @State private var detent = PresentationDetent.medium
    @State private var isSheetPresented = false
    @State private var mapHeight: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shown: [MapSearchSheetPlace] {
        MapSearchSheetLogic.matches(places, query: query)
    }

    var body: some View {
        Map(position: $position, selection: $selection) {
            ForEach(shown) { place in
                Marker(place.name, systemImage: place.symbol, coordinate: place.coordinate)
                    .tag(place.id)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        // The whole height, safe area included: the padding below changes the safe area, and a
        // height that changed with it would never settle.
        .onGeometryChange(for: CGFloat.self) { proxy in
            (proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom).rounded()
        } action: { mapHeight = $0 }
        // Keeps what the map centers on, and its legal label, in the part the sheet leaves free.
        .safeAreaPadding(.bottom, detent == Self.resting ? Self.restingHeight : mapHeight / 2)
        .onChange(of: selection) { _, id in
            guard let place = places.first(where: { $0.id == id }) else { return }
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.8)) {
                position = .camera(MapCamera(centerCoordinate: place.coordinate, distance: closeUpDistance))
            }
        }
        .onChange(of: query) {
            selection = nil
            withAnimation(reduceMotion ? nil : .smooth) { position = .automatic }
        }
        .sheet(isPresented: $isSheetPresented) {
            MapSearchSheetPanel(places: shown, prompt: prompt, query: $query, selection: $selection, detent: $detent)
                .presentationDetents([Self.resting, .medium, .large], selection: $detent)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
        }
        .onAppear { isSheetPresented = true }
        .onDisappear { isSheetPresented = false }
    }
}

/// What the sheet shows: the search field and the places. It is a view of its own because the
/// focus of a field in a sheet has to be kept inside the sheet.
private struct MapSearchSheetPanel: View {
    let places: [MapSearchSheetPlace]
    let prompt: String
    @Binding var query: String
    @Binding var selection: MapSearchSheetPlace.ID?
    @Binding var detent: PresentationDetent

    @FocusState private var isSearching: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                TextField(prompt, text: $query)
                    .focused($isSearching)
                    .submitLabel(.search)
                    .autocorrectionDisabled()

                if !query.isEmpty {
                    Button("Clear", systemImage: "xmark.circle.fill") {
                        query = ""
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(.fill.tertiary, in: .rect(cornerRadius: 12))
            .padding(.horizontal, 16)
            .padding(.top, 22)
            .padding(.bottom, 12)

            if places.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                List(places) { place in
                    Button {
                        isSearching = false
                        selection = place.id
                        detent = .medium
                    } label: {
                        row(place)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(place.id == selection ? Color.accentColor.opacity(0.12) : Color.clear)
                    .accessibilityAddTraits(place.id == selection ? .isSelected : [])
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .onChange(of: isSearching) { _, searching in
            if searching { detent = .large }
        }
    }

    private func row(_ place: MapSearchSheetPlace) -> some View {
        HStack(spacing: 12) {
            Image(systemName: place.symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.tint, in: .circle)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(place.name)
                    .font(.headline)
                Text(place.kind)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Demo

struct MapSearchSheetDemo: View {
    private let places = [
        MapSearchSheetPlace(id: "coffee", name: "Harbor Coffee", kind: "Café", symbol: "cup.and.saucer.fill", latitude: 38.7109, longitude: -9.1422),
        MapSearchSheetPlace(id: "bakery", name: "Blue Door Bakery", kind: "Bakery", symbol: "birthday.cake.fill", latitude: 38.7139, longitude: -9.1389),
        MapSearchSheetPlace(id: "books", name: "Old Town Books", kind: "Bookshop", symbol: "book.fill", latitude: 38.7118, longitude: -9.1331),
        MapSearchSheetPlace(id: "park", name: "Riverside Garden", kind: "Park", symbol: "tree.fill", latitude: 38.7076, longitude: -9.1362),
        MapSearchSheetPlace(id: "market", name: "Corner Market", kind: "Grocery", symbol: "cart.fill", latitude: 38.7163, longitude: -9.1432),
        MapSearchSheetPlace(id: "museum", name: "Tile Museum Café", kind: "Café", symbol: "cup.and.saucer.fill", latitude: 38.7157, longitude: -9.1338),
        MapSearchSheetPlace(id: "diner", name: "Tram Stop Diner", kind: "Restaurant", symbol: "fork.knife", latitude: 38.7095, longitude: -9.1301),
    ]

    var body: some View {
        MapSearchSheet(places: places)
            .tint(.indigo)
    }
}

#Preview {
    MapSearchSheetDemo()
}
