// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

struct ComponentDetailView: View {
    let entry: ShowcaseEntry

    var body: some View {
        content
            .navigationTitle(entry.title)
            .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var content: some View {
        if let demo = entry.demo() {
            demo
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ContentUnavailableView(
                "Requires iOS \(entry.minIOS)",
                systemImage: "iphone.slash",
                description: Text("Run the Showcase on a newer iOS to see this component.")
            )
        }
    }
}
