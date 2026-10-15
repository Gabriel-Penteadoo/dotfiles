// Neovide cursor, ported 1:1 from neovide/neovide src/renderer/cursor_renderer
// (mod.rs Corner::jump / calculate_direction_alignment, animation_utils.rs
// CriticallyDampedSpringAnimation), with Neovide's default settings.
//
// Each corner gets its own animation length from how well it faces the
// direction of travel: front corners land instantly, back corners trail for
// ANIMATION_LENGTH. Moves of <= 2 cells on the same line (typing) use the short
// length for every corner. Springs are critically damped: no overshoot.
//
// Ghostty's own cursor is hidden (cursor-opacity = 0 in the config) and this
// shader draws the whole cursor, including the inverted character under it.
//
// Differences from Neovide that a shader can't avoid: Ghostty only gives the
// previous and current cursor rect, so a move that interrupts a running
// animation restarts from the previous cell instead of the corner's current
// position and velocity.

// Neovide settings (vim.g.neovide_cursor_*), defaults
const float ANIMATION_LENGTH = 0.150;       // neovide_cursor_animation_length
const float SHORT_ANIMATION_LENGTH = 0.04;  // neovide_cursor_short_animation_length
const float TRAIL_SIZE = 1.0;               // neovide_cursor_trail_size (0..1)
const float FRAME_DT = 1.0 / 60.0;          // display frame time; shorter animations snap, like Neovide

// Not part of Neovide's defaults (Neovim's default guicursor doesn't blink)
const float BLINK_DELAY = 0.8;   // seconds after a move before blinking starts (<0 disables)
const float BLINK_PERIOD = 1.0;  // full on/off cycle in seconds

// Signed distance to a quad (any shape, negative inside) - after iq's sdPolygon
float sdQuad(vec2 p, vec2 v0, vec2 v1, vec2 v2, vec2 v3) {
    vec2 v[4] = vec2[4](v0, v1, v2, v3);
    float d = dot(p - v[0], p - v[0]);
    float s = 1.0;
    for (int i = 0, j = 3; i < 4; j = i, i++) {
        vec2 e = v[j] - v[i];
        vec2 w = p - v[i];
        vec2 b = w - e * clamp(dot(w, e) / max(dot(e, e), 1e-8), 0.0, 1.0);
        d = min(d, dot(b, b));
        bvec3 c = bvec3(p.y >= v[i].y, p.y < v[j].y, e.x * w.y > e.y * w.x);
        if (all(c) || all(not(c))) s *= -1.0;
    }
    return s * sqrt(d);
}

// Critically damped spring (zeta = 1, omega = 4 / length), released from rest
// with offset 1: remaining offset after t seconds. Neovide resets an animation
// whose length is <= one frame, i.e. it jumps straight to the destination.
float remaining(float len, float t) {
    if (len <= FRAME_DT) return 0.0;
    float omega = 4.0 / len;
    return (1.0 + omega * t) * exp(-omega * t);
}

// Corner::jump: per-corner animation length
float cornerLength(vec2 jumpCells, float alignment) {
    if (abs(jumpCells.x) <= 2.001 && abs(jumpCells.y) <= 0.001)
        return min(ANIMATION_LENGTH, SHORT_ANIMATION_LENGTH);
    float leading = ANIMATION_LENGTH * clamp(1.0 - TRAIL_SIZE, 0.0, 1.0);
    float trailing = ANIMATION_LENGTH;
    return mix(trailing, leading, alignment);
}

// calculate_direction_alignment: corner direction . travel direction
float alignmentOf(vec2 cornerDir, vec2 travel) {
    float len = length(travel);
    return len > 0.0 ? dot(normalize(cornerDir), travel / len) : 0.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 pixel = texture(iChannel0, uv);
    fragColor = pixel;

    // Cursor rects are (left, top, width, height) in pixels, y up
    vec4 c = iCurrentCursor;
    vec4 p = iPreviousCursor;
    if (c.z < 1.0 || c.w < 1.0) return; // no cursor to draw

    vec2 cTL = c.xy, cTR = c.xy + vec2(c.z, 0.0);
    vec2 cBR = c.xy + vec2(c.z, -c.w), cBL = c.xy + vec2(0.0, -c.w);
    vec2 pTL = p.xy, pTR = p.xy + vec2(p.z, 0.0);
    vec2 pBR = p.xy + vec2(p.z, -p.w), pBL = p.xy + vec2(0.0, -p.w);

    float t = iTime - iTimeCursorChange;
    vec2 delta = (c.xy + vec2(c.z, -c.w) * 0.5) - (p.xy + vec2(p.z, -p.w) * 0.5);

    vec2 q0 = cTL, q1 = cTR, q2 = cBR, q3 = cBL;
    // Animations last at most ANIMATION_LENGTH-ish; by 3x the offset is < 0.01%.
    // Ghostty only redraws continuously while focused, so never animate unfocused
    bool moving = iFocus == 1 && t < ANIMATION_LENGTH * 3.0 && length(delta) > 0.5;
    if (moving) {
        // Neovide's STANDARD_CORNERS (-0.5,-0.5) (0.5,-0.5) (0.5,0.5) (-0.5,0.5)
        // are y-down; here y is up, so TL = (-1, 1) etc. Dot products are unchanged.
        vec4 a = vec4(alignmentOf(vec2(-1.0,  1.0), cTL - pTL),
                      alignmentOf(vec2( 1.0,  1.0), cTR - pTR),
                      alignmentOf(vec2( 1.0, -1.0), cBR - pBR),
                      alignmentOf(vec2(-1.0, -1.0), cBL - pBL));
        // Normalise to 0..1 across the four corners (all equal -> 1, like Neovide's NaN case)
        float lo = min(min(a.x, a.y), min(a.z, a.w));
        float hi = max(max(a.x, a.y), max(a.z, a.w));
        a = hi - lo > 1e-6 ? clamp((a - lo) / (hi - lo), 0.0, 1.0) : vec4(1.0);

        vec2 cell = vec2(c.z, c.w);
        vec4 r = vec4(remaining(cornerLength((cTL - pTL) / cell, a.x), t),
                      remaining(cornerLength((cTR - pTR) / cell, a.y), t),
                      remaining(cornerLength((cBR - pBR) / cell, a.z), t),
                      remaining(cornerLength((cBL - pBL) / cell, a.w), t));
        q0 = mix(cTL, pTL, r.x);
        q1 = mix(cTR, pTR, r.y);
        q2 = mix(cBR, pBR, r.z);
        q3 = mix(cBL, pBL, r.w);
    }

    // Blink only while resting and focused
    if (!moving && iFocus == 1 && BLINK_DELAY >= 0.0 && t > BLINK_DELAY &&
        fract((t - BLINK_DELAY) / BLINK_PERIOD) > 0.5) return;

    float sd = sdQuad(fragCoord, q0, q1, q2, q3);
    float alpha = 1.0 - smoothstep(-0.75, 0.75, sd);

    // Unfocused window: hollow outline at rest
    if (iFocus == 0 && !moving) {
        float inner = 1.0 - smoothstep(-0.75, 0.75, sd + 1.5);
        alpha -= inner;
    }
    if (alpha <= 0.0) return;

    vec3 cursorColor = iCurrentCursorColor.rgb;

    // Background of the destination cell, sampled at its top-left corner
    vec3 bg = texture(iChannel0, (cTL + vec2(0.5, -0.5)) / iResolution.xy).rgb;

    // Text pixels (anything that differs from the cell background) are drawn in
    // the background color so the character stays readable inside the block
    float ink = clamp(length(pixel.rgb - bg) * 3.0, 0.0, 1.0);
    vec3 filled = mix(cursorColor, bg, ink);
    if (iFocus == 0 && !moving) filled = cursorColor;

    fragColor.rgb = mix(pixel.rgb, filled, alpha);
    fragColor.a = mix(pixel.a, 1.0, alpha); // keep the cursor solid over a transparent background
}
