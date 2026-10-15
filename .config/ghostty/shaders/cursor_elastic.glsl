// Elastic cursor: the leading edge shoots ahead, the trailing edge catches up,
// and the block squashes slightly while stretched. Works in every direction.

// Tweakables
const float DURATION = 0.22;    // seconds for the whole animation
const float LEAD_SPEED = 3.0;   // >1: leading edge arrives before the trailing edge
const float SQUASH = 0.35;      // 0 = no squash, 0.35 = shrink 35% across the stretch at max
const float SQUASH_CELLS = 6.0; // stretch length (in cursor widths) for full squash
const float OPACITY = 0.9;

float easeOutCubic(float x) {
    float t = 1.0 - clamp(x, 0.0, 1.0);
    return 1.0 - t * t * t;
}

void processEdge(vec2 p, vec2 a, vec2 b, inout float minDist, inout float inside) {
    vec2 edge = b - a;
    vec2 pa = p - a;
    float lenSq = max(dot(edge, edge), 1e-8);
    float t = clamp(dot(pa, edge) / lenSq, 0.0, 1.0);
    vec2 diff = pa - edge * t;
    minDist = min(minDist, dot(diff, diff));
    float cross = edge.x * pa.y - edge.y * pa.x;
    inside = min(inside, step(0.0, cross));
}

// Signed distance to a CCW hexagon (negative inside)
float sdHexagon(vec2 p, vec2 v0, vec2 v1, vec2 v2, vec2 v3, vec2 v4, vec2 v5) {
    float minDist = 1e20;
    float inside = 1.0;
    processEdge(p, v0, v1, minDist, inside);
    processEdge(p, v1, v2, minDist, inside);
    processEdge(p, v2, v3, minDist, inside);
    processEdge(p, v3, v4, minDist, inside);
    processEdge(p, v4, v5, minDist, inside);
    processEdge(p, v5, v0, minDist, inside);
    float dist = sqrt(max(minDist, 0.0));
    return mix(dist, -dist, inside);
}

struct Quad { vec2 tl; vec2 tr; vec2 bl; vec2 br; };

// Quad from center + half size (y up)
Quad quadAt(vec2 c, vec2 h) {
    Quad q;
    q.tl = c + vec2(-h.x,  h.y);
    q.tr = c + vec2( h.x,  h.y);
    q.bl = c + vec2(-h.x, -h.y);
    q.br = c + vec2( h.x, -h.y);
    return q;
}

// Corners forming the convex hull of two rects, given movement direction.
// sel.x: 1 = moving right, sel.y: 1 = moving up
void trailCorners(Quad q, vec2 sel, out vec2 p1, out vec2 p2, out vec2 p3) {
    p1 = mix(mix(q.tr, q.tl, sel.x), mix(q.br, q.bl, sel.x), sel.y);
    p2 = mix(mix(q.tl, q.bl, sel.x), mix(q.tr, q.br, sel.x), sel.y);
    p3 = mix(mix(q.br, q.tr, sel.x), mix(q.bl, q.tl, sel.x), sel.y);
}

void leadCorners(Quad q, vec2 sel, out vec2 p2, out vec2 p3, out vec2 p4) {
    vec2 p1;
    trailCorners(q, sel, p1, p2, p3);
    p4 = mix(mix(q.bl, q.br, sel.x), mix(q.tl, q.tr, sel.x), sel.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    fragColor = texture(iChannel0, uv);

    float progress = (iTime - iTimeCursorChange) / DURATION;
    if (progress >= 1.0) return;

    // Work in pixels, cursor rects given as (left, top, width, height), y up
    vec2 curSize = iCurrentCursor.zw;
    vec2 prevSize = iPreviousCursor.zw;
    vec2 curCenter = iCurrentCursor.xy + vec2(curSize.x, -curSize.y) * 0.5;
    vec2 prevCenter = iPreviousCursor.xy + vec2(prevSize.x, -prevSize.y) * 0.5;

    vec2 delta = curCenter - prevCenter;
    float moveLen = length(delta);
    if (moveLen < 0.5) return;

    float leadT = easeOutCubic(progress * LEAD_SPEED);
    float trailT = easeOutCubic(progress);

    vec2 leadC = mix(prevCenter, curCenter, leadT);
    vec2 trailC = mix(prevCenter, curCenter, trailT);
    vec2 size = mix(prevSize, curSize, leadT);

    // Squash across the direction of travel, proportional to stretch
    float stretch = length(leadC - trailC) / max(curSize.x * SQUASH_CELLS, 1.0);
    float squash = 1.0 - SQUASH * clamp(stretch, 0.0, 1.0);
    vec2 dir = abs(delta) / moveLen;           // 1 on the dominant axis
    vec2 across = vec2(dir.y, dir.x);          // perpendicular axis weight
    vec2 halfSize = size * 0.5 * mix(vec2(1.0), vec2(squash), across);

    vec2 sel = step(vec2(0.0), delta);
    vec2 t1, t2, t3, l2, l3, l4;
    trailCorners(quadAt(trailC, halfSize), sel, t1, t2, t3);
    leadCorners(quadAt(leadC, halfSize), sel, l2, l3, l4);

    float sd = sdHexagon(fragCoord, t1, t2, l2, l4, l3, t3);
    float alpha = (1.0 - smoothstep(-1.0, 1.0, sd)) * OPACITY;

    fragColor.rgb = mix(fragColor.rgb, iCurrentCursorColor.rgb, alpha);
}
