"""GATOS crew test: a 3/4 view standing figure on a 70 x 70 frame, built in stages.
Body parts are polygons drawn back to front, each with a 4-tone ramp (deep, shadow, base, light), hue-shifted, light
from the upper left. Heads and hands are hand-placed pixel grids ("sprite" parts) with their own tones.
Stages: 1 silhouette, 2 flat colours, 3 shading, 4 highlights and selective outline, 5 details."""

W = H = 70


def poly(points):
    xs = [p[0] for p in points]; ys = [p[1] for p in points]
    out = set()
    for y in range(int(min(ys)) - 1, int(max(ys)) + 2):
        for x in range(int(min(xs)) - 1, int(max(xs)) + 2):
            px, py = x + .5, y + .5
            inside, j = False, len(points) - 1
            for i in range(len(points)):
                xi, yi = points[i]; xj, yj = points[j]
                if (yi > py) != (yj > py) and px < (xj - xi) * (py - yi) / (yj - yi) + xi:
                    inside = not inside
                j = i
            if inside:
                out.add((x, y))
    return out


def ellipse(cx, cy, rx, ry):
    return {(x, y) for y in range(int(cy - ry) - 1, int(cy + ry) + 2) for x in range(int(cx - rx) - 1, int(cx + rx) + 2)
            if ((x + .5 - cx) / rx) ** 2 + ((y + .5 - cy) / ry) ** 2 <= 1}


def grid(x0, y0, rows, key):
    """A hand-placed pixel grid: key maps a letter to (ramp, tone) or to a literal colour string."""
    return {(x0 + x, y0 + y): key[ch] for y, row in enumerate(rows) for x, ch in enumerate(row) if ch in key}


def part(name, mask, ramp, kind="flat"):
    return (name, mask, ramp, kind)


def sprite(name, cells):
    return (name, set(cells), cells, "sprite")


def render(parts, details=(), stage=5):
    owner = {}
    for i, pt in enumerate(parts):
        for p in pt[1]:
            owner[p] = i
    if stage == 1:
        return {p: "#20242c" for p in owner}

    def colour(p, t):
        name, mask, ramp, kind = parts[owner[p]]
        if kind == "sprite":
            v = ramp[p]
            if isinstance(v, str):
                return v
            r, tt = v
            return r[2] if stage == 2 else r[tt]
        return ramp[t]

    tone = {p: 2 for p in owner}
    if stage >= 3:
        for p, i in owner.items():
            name, mask, ramp, kind = parts[i]
            if kind == "sprite":
                continue
            x, y = p
            da = next((k for k in range(1, 8) if (x + k, y) not in mask), 8)
            dl = next((k for k in range(1, 8) if (x - k, y) not in mask), 8)
            db = next((k for k in range(1, 8) if (x, y + k) not in mask), 8)
            if kind == "round":
                if da <= max(1, (da + dl) // 3):
                    tone[p] = 1
            elif da <= 1 or db <= 1:
                tone[p] = 1
            # shade cast by a part in front, up and to the left
            for q in ((x - 1, y), (x, y - 1), (x - 1, y - 1)):
                if q in owner and owner[q] > i:
                    tone[p] = min(tone[p], 1)
                    break
    if stage >= 4:
        for p, i in owner.items():
            name, mask, ramp, kind = parts[i]
            if kind == "sprite":
                continue
            x, y = p
            lit_edge = (x - 1, y) not in mask or (x, y - 1) not in mask
            if tone[p] == 2 and lit_edge and ((x - 1, y) not in owner or owner[(x - 1, y)] < i) \
                    and ((x, y - 1) not in owner or owner[(x, y - 1)] < i):
                tone[p] = 3
        for p, i in owner.items():
            if parts[i][3] == "sprite":
                continue
            x, y = p
            if any(q not in owner for q in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))):
                lit = (x + 1, y) in owner and (x, y + 1) in owner
                tone[p] = 1 if lit else 0
    px = {p: colour(p, tone[p]) for p in owner}
    if stage >= 5:
        for (x, y), c in details:
            px[(x, y)] = c
    return px
