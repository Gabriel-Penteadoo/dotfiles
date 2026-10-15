// Neovide-style cursor: each corner rides its own spring. Corners facing the
// direction of travel move faster than the ones behind, so the block stretches
// and tilts as it flies, overshoots the target and wobbles into place.
//
// Ghostty's own cursor is hidden (cursor-opacity = 0 in the config) and this
// shader draws the whole cursor, including the inverted character under it.

// Tweakables
const float FREQUENCY = 5.0;     // spring oscillations per second (higher = snappier)
const float DAMPING = 0.6;       // ~0.9 = no bounce (keep < 1.0), lower = more bounce/wobble (was 0.38)
const float LEAD_SPEED = 2.0;    // time multiplier for leading corners
const float TRAIL_SPEED = 0.5;   // time multiplier for trailing corners (lower = more stretch)
const float TILT = -10.0;         // lean: >0 top edge leads (leans forward), <0 bottom leads (top drags behind), 0 = none
const float MAX_LAG = 1.2;       // most a corner may trail the leader, in cells (keeps big jumps tame)
const float MAX_DURATION = 1.0;  // hard stop in seconds
const float BLINK_DELAY = 0.8;   // seconds after a move before blinking starts (<0 disables)
const float BLINK_PERIOD = 1.0;  // full on/off cycle in seconds

// Underdamped spring step response: 0 -> 1 with overshoot
float spring(float t) {
    float w = 6.2831853 * FREQUENCY;
    float z = DAMPING;
    float wd = w * sqrt(1.0 - z * z);
    float env = exp(-z * w * t);
    return 1.0 - env * (cos(wd * t) + (z * w / wd) * sin(wd * t));
}

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

// How much a corner leads: facing the movement, plus a bias toward one side
// (the top edge on horizontal moves when TILT > 0, the bottom edge when < 0)
float cornerScore(vec2 cornerDir, vec2 moveDir, vec2 perp) {
    return dot(cornerDir, moveDir) + TILT * dot(cornerDir, perp);
}

// score in [-1, 1]: +1 leads the way, -1 trails furthest behind
float cornerProgress(float score, float t) {
    float speed = mix(TRAIL_SPEED, LEAD_SPEED, score * 0.5 + 0.5);
    return spring(t * speed);
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
    float moveLen = length(delta);

    vec2 q0 = cTL, q1 = cTR, q2 = cBR, q3 = cBL;
    // Ghostty only redraws continuously while focused, so never animate unfocused
    bool moving = iFocus == 1 && t < MAX_DURATION && moveLen > 0.5;
    if (moving) {
        vec2 moveDir = delta / moveLen;
        // Perpendicular that points up for horizontal moves either way
        vec2 perp = vec2(-moveDir.y, moveDir.x) * (moveDir.x < 0.0 ? -1.0 : 1.0);
        float s0 = cornerScore(vec2(-1.0,  1.0), moveDir, perp);
        float s1 = cornerScore(vec2( 1.0,  1.0), moveDir, perp);
        float s2 = cornerScore(vec2( 1.0, -1.0), moveDir, perp);
        float s3 = cornerScore(vec2(-1.0, -1.0), moveDir, perp);
        float norm = max(max(abs(s0), abs(s1)), max(abs(s2), abs(s3)));
        vec4 sc = vec4(s0, s1, s2, s3) / norm;
        vec4 k = vec4(cornerProgress(sc.x, t), cornerProgress(sc.y, t),
                      cornerProgress(sc.z, t), cornerProgress(sc.w, t));
        // A corner never gets ahead of one that leads it, otherwise the
        // bounce flips the lean and the quad crosses itself into a bow-tie
        vec4 kc = k;
        for (int i = 0; i < 4; i++)
            for (int j = 0; j < 4; j++)
                if (sc[j] > sc[i]) kc[i] = min(kc[i], k[j]);
        // Lag is a fraction of the distance, so long jumps would stretch across
        // the screen; soft-cap how far (in pixels) any corner trails the leader.
        // tanh is monotonic, so the corner order (and the no-bow-tie rule) holds
        float lead = max(max(kc.x, kc.y), max(kc.z, kc.w));
        float capPx = MAX_LAG * max(c.z, 1.0);
        kc = lead - capPx * tanh((lead - kc) * moveLen / capPx) / moveLen;
        q0 = mix(pTL, cTL, kc.x);
        q1 = mix(pTR, cTR, kc.y);
        q2 = mix(pBR, cBR, kc.z);
        q3 = mix(pBL, cBL, kc.w);
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
