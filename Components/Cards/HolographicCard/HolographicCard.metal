// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

// A repeatable pseudo-random number from 0 to 1 for each cell of a grid.
static float HolographicCardRandom(float2 cell) {
    uint2 seed = uint2(int2(cell));
    uint mixed = (seed.x * 0x9E3779B1u) ^ (seed.y * 0x85EBCA77u);
    mixed ^= mixed >> 15;
    mixed *= 0x2C1B3C6Du;
    mixed ^= mixed >> 12;
    return float(mixed & 0xFFFFu) / 65535.0;
}

// For SwiftUI's `colorEffect`. Adds a holographic foil to each pixel of a view
// of `size` points. `tilt` runs from -1 to 1 on each axis, and moves the colors
// and the glare as a real card does when it turns under a light.
[[ stitchable ]] half4 HolographicCardFoil(float2 position, half4 color, float2 size, float2 tilt, float intensity) {
    if (color.a <= 0.0) {
        return color;
    }
    float2 fromCenter = position / max(size, float2(1.0)) - 0.5;

    // A diffraction foil changes hue with the viewing angle, so its bands of
    // color slide across the card as it tilts.
    float angle = dot(fromCenter, float2(0.9, 0.5)) * 1.4 + dot(tilt, float2(0.8, 0.6));
    float3 spectrum = 0.5 + 0.5 * cos(6.2831853 * (angle + float3(0.0, 0.33, 0.67)));

    // Specks of glitter, one in each cell of a grid and somewhere off its
    // center. Each catches the light at its own angle, so they twinkle in turn.
    float2 grid = position / 5.0;
    float2 cell = floor(grid);
    float2 speck = 0.5 + 0.56 * (float2(HolographicCardRandom(cell + 17.0), HolographicCardRandom(cell + 43.0)) - 0.5);
    float shape = saturate(1.0 - length(grid - cell - speck) / 0.22);
    float facing = 0.5 + 0.5 * cos(6.2831853 * (HolographicCardRandom(cell) + angle * 2.0));
    float glint = smoothstep(0.55, 1.0, facing) * shape * shape;

    // The glare of a light above the card slides against the tilt.
    float2 fromGlare = fromCenter + tilt * 0.35;
    float glare = exp(-6.0 * dot(fromGlare, fromGlare));

    float3 foil = intensity * (spectrum * (0.14 + 0.4 * glare) + glint * (0.3 + 0.7 * glare));

    // Screen the foil over the pixel, so it only ever adds light. Colors come
    // premultiplied by their alpha.
    float3 base = float3(color.rgb) / color.a;
    float3 lit = 1.0 - (1.0 - base) * (1.0 - saturate(foil));
    return half4(half3(lit * color.a), color.a);
}
