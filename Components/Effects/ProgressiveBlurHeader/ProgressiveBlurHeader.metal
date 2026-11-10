// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

// For SwiftUI's `layerEffect`. Blurs along `direction` with a reach that is
// `radius` at `top`, the line where the header starts, and falls smoothly to
// nothing `height` points below it. One pass across and one pass down make
// the whole blur, with far fewer samples than doing both at once.
[[ stitchable ]] half4 ProgressiveBlurHeaderPass(
    float2 position,
    SwiftUI::Layer layer,
    float top,
    float height,
    float radius,
    float2 direction
) {
    float reach = radius * (1.0 - smoothstep(0.0, height, position.y - top));
    if (reach < 0.5) {
        return layer.sample(position);
    }

    // Samples spread over the reach, weighted like a bell so the middle counts most.
    const int steps = 8;
    half4 total = half4(0.0);
    float weights = 0.0;
    for (int step = -steps; step <= steps; step++) {
        float offset = float(step) / float(steps);
        float weight = exp(-2.0 * offset * offset);
        total += layer.sample(position + direction * offset * reach) * half(weight);
        weights += weight;
    }
    return total / half(weights);
}
