// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

// A repeatable pseudo-random number from 0 to 1 for each cell of a grid.
static float DissolveShaderTransitionRandom(float2 cell) {
    uint2 seed = uint2(int2(cell));
    uint mixed = (seed.x * 0x9E3779B1u) ^ (seed.y * 0x85EBCA77u);
    mixed ^= mixed >> 15;
    mixed *= 0x2C1B3C6Du;
    mixed ^= mixed >> 12;
    return float(mixed & 0xFFFFu) / 65535.0;
}

// Smooth noise from 0 to 1: a random value at each corner of a grid, blended
// across each cell.
static float DissolveShaderTransitionNoise(float2 point) {
    float2 cell = floor(point);
    float2 inside = point - cell;
    float2 blend = inside * inside * (3.0 - 2.0 * inside);

    float bottom = mix(
        DissolveShaderTransitionRandom(cell),
        DissolveShaderTransitionRandom(cell + float2(1.0, 0.0)),
        blend.x
    );
    float top = mix(
        DissolveShaderTransitionRandom(cell + float2(0.0, 1.0)),
        DissolveShaderTransitionRandom(cell + float2(1.0, 1.0)),
        blend.x
    );
    return mix(bottom, top, blend.y);
}

// For SwiftUI's `colorEffect`. Removes the pixels whose noise is under
// `threshold`, and makes the ones within `edgeWidth` above it glow in
// `edgeColor`, so the view burns away in patches of `grain` points.
[[ stitchable ]] half4 DissolveShaderTransitionBurn(
    float2 position,
    half4 color,
    float threshold,
    float edgeWidth,
    float grain,
    half4 edgeColor
) {
    // Large patches, with a finer layer that roughens their outline.
    float2 point = position / grain;
    float noise = 0.7 * DissolveShaderTransitionNoise(point)
        + 0.3 * DissolveShaderTransitionNoise(point * 3.1 + 17.0);
    // Noise gathers around the middle. Spreading it makes the burn last the
    // whole transition.
    noise = saturate((noise - 0.5) * 1.7 + 0.5);

    // A short ramp keeps the cut from looking jagged.
    float kept = smoothstep(threshold, threshold + 0.015, noise);
    float heat = 1.0 - smoothstep(threshold, threshold + edgeWidth, noise);

    // The edge is the color of the ember, and paler where it is hottest.
    // Colors come premultiplied by their alpha.
    half3 ember = mix(edgeColor.rgb, half3(1.0), half(0.35 * heat * heat)) * color.a;
    half3 burning = mix(color.rgb, ember, half(heat));
    return half4(burning, color.a) * half(kept);
}
