"""Mecha Light Attack Frame floor plans on the battle cross, in the Mecha pixel style.

Usage: python3 floor_bc.py OUT_DIR
Writes floor-LOADOUT.svg (rooms, doors, airlocks, consoles, the big machines) and plan-LOADOUT.svg (the sleek hull
with the floor) for the hull-laser and suit-dock loadouts. Systems are self-powered (no reactor), so there are no
conduits. Symbols are Mecha power purple (an enemy ship shows its own race's power colour).

Checks: every room sits under the hull; no console stands on a door tile; every door joins two rooms and every
airlock opens to space; one console per tile; consoles keep their tile walkable (art rules).
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "console", "tools"))
import hull_bc_sleek as hull    # noqa: E402
import tower_px as tp           # noqa: E402

T, X0, Y0, W, H = 35, hull.X0, hull.Y0, hull.W, hull.H
PURPLE, DEEP, PALE = "#aa28eb", "#5a128c", "#ebe1fa"
OUTLINE, WALL, RIM = "#0a0a0e", "#1c1d24", "#3d414d"
FLOOR = ["#6f747d", "#878c95", "#9da2aa", "#b3b8bf"]      # seam, scuff, base, lit lip
DOOR, DOOR_EDGE, AIRLOCK = "#7a7f8e", "#2e3039", "#3d414d"

# the battle cross (heromedel's pick); the engine room is 4 x 1 so its two consoles and its door each get a tile
ROOMS = {"command": (2, 0, 2, 2), "second bay": (0, 1, 2, 2), "weapon bay": (4, 1, 2, 2), "core": (2, 2, 2, 2),
         "engine room": (1, 4, 4, 1)}
DOORS = [(2, 1, "s"), (2, 2, "w"), (3, 2, "e"), (2, 3, "s")]          # (col, row, wall)
AIRLOCKS = [(0, 1, "w"), (0, 2, "w")]                                   # in the spare bay; not marked on the hull
CONSOLES = [("Piloting", 2, 0, "n", "piloting"), ("Shields", 3, 0, "n", "shields"), ("Doors", 3, 1, "e", "doors"),
            ("Engines", 1, 4, "w", "engines"), ("Life Support", 4, 4, "e", "life")]
LOADOUT = {"hull-laser": [("Weapon pod", 5, 1, "e", "weapons")], "suit-dock": [("EVB Dock", 5, 1, "e", "evb")]}
CORE = (2, 3)        # the Servicing Core's cradle, over two tiles against the south wall (walkable)
CLAMP = (5, 2)       # the Suit Dock's launch clamp at the bay's outer wall (walkable)
STEP = {"n": (0, -1), "s": (0, 1), "w": (-1, 0), "e": (1, 0)}

# 7 x 7 system symbols, upright
SYM = {
    "piloting": ["...#...", "..###..", ".#####.", "###.###", "##...##", "#.....#", "......."],
    "shields":  [".#####.", "#.....#", "..###..", ".#...#.", "...#...", "..#.#..", "......."],
    "doors":    ["##.##..", "##.##..", "##.##..", "##.##..", "##.##..", "##.##..", "......."],
    "engines":  ["#......", "##.#...", "#####..", "#######", "#####..", "##.#...", "#......"],
    "life":     ["..###..", ".#...#.", "#.#.#.#", "#..#..#", "#.#.#.#", ".#...#.", "..###.."],
    "weapons":  ["..###..", ".#.#.#.", "#..#..#", "#######", "#..#..#", ".#.#.#.", "..###.."],
    "evb":      ["..###..", "..#.#..", "..###..", ".......", "#######", "#######", "##...##"],
    "medbay":   ["..###..", "..###..", "#######", "#######", "#######", "..###..", "..###.."],
}
SYM["doors"] = [r[:5].rjust(6, ".") + "." for r in SYM["doors"]]
TURN = {"n": lambda x, y: (x, y), "e": lambda x, y: (34 - y, x), "s": lambda x, y: (34 - x, 34 - y),
        "w": lambda x, y: (y, 34 - x)}


def cell(c, r):
    return X0 + c * T, Y0 + r * T


def room_of(c, r):
    for name, (rc, rr, w, h) in ROOMS.items():
        if rc <= c < rc + w and rr <= r < rr + h:
            return name
    return None


def check(loadout, hull_px):
    for name, (c, r, w, h) in ROOMS.items():
        x, y = cell(c, r)
        missing = [(xx, yy) for xx in range(x - 4, x + w * T + 4) for yy in range(y - 4, y + h * T + 4) if (xx, yy) not in hull_px]
        assert not missing, (name, missing[:3])
    door_tiles = set()
    for c, r, side in DOORS:
        dc, dr = STEP[side]
        assert room_of(c, r) and room_of(c + dc, r + dr) and room_of(c, r) != room_of(c + dc, r + dr), (c, r, side)
        door_tiles |= {(c, r), (c + dc, r + dr)}
    for c, r, side in AIRLOCKS:
        dc, dr = STEP[side]
        assert room_of(c, r) and room_of(c + dc, r + dr) is None, (c, r, side)
        door_tiles.add((c, r))
    tiles = [(c, r) for _, c, r, _, _ in CONSOLES + LOADOUT[loadout]]
    assert len(tiles) == len(set(tiles)), "two consoles on one tile"
    for name, c, r, wall, _ in CONSOLES + LOADOUT[loadout]:
        dc, dr = STEP[wall]
        assert room_of(c, r) and room_of(c + dc, r + dr) != room_of(c, r), (name, "not against a wall")
        assert (c, r) not in door_tiles, (name, "on a door tile")


def rect(px, x0, y0, x1, y1, col):
    for y in range(y0, y1):
        for x in range(x0, x1):
            px[(x, y)] = col


def floor(px):
    for name, (c, r, w, h) in ROOMS.items():
        x0, y0 = cell(c, r)
        for y in range(y0, y0 + h * T):
            for x in range(x0, x0 + w * T):
                fx, fy = (x - x0) % T, (y - y0) % T
                col = FLOOR[0] if fx == 0 or fy == 0 else FLOOR[3] if fx == 1 or fy == 1 else FLOOR[2]
                if (fx, fy) in ((3, 3), (31, 3), (3, 31), (31, 31)):
                    col = FLOOR[1]
                px[(x, y)] = col
    for name, (c, r, w, h) in ROOMS.items():   # walls: dark, with a lit inner rim
        x0, y0 = cell(c, r)
        x1, y1 = x0 + w * T, y0 + h * T
        for x in range(x0 - 2, x1 + 2):
            for y in (y0 - 2, y0 - 1, y1, y1 + 1):
                px[(x, y)] = OUTLINE if y in (y0 - 2, y1 + 1) else WALL
        for y in range(y0 - 2, y1 + 2):
            for x in (x0 - 2, x0 - 1, x1, x1 + 1):
                px[(x, y)] = OUTLINE if x in (x0 - 2, x1 + 1) else WALL
        for x in range(x0, x1):
            if px.get((x, y0)) != OUTLINE:
                px[(x, y0)] = RIM


def door(px, c, r, side, col):
    x0, y0 = cell(c, r)
    if side in ("n", "s"):
        y = y0 - 2 if side == "n" else y0 + T - 2
        rect(px, x0 + 9, y, x0 + 26, y + 4, DOOR_EDGE)
        rect(px, x0 + 10, y + 1, x0 + 17, y + 3, col)
        rect(px, x0 + 18, y + 1, x0 + 25, y + 3, col)
    else:
        x = x0 - 2 if side == "w" else x0 + T - 2
        rect(px, x, y0 + 9, x + 4, y0 + 26, DOOR_EDGE)
        rect(px, x + 1, y0 + 10, x + 3, y0 + 17, col)
        rect(px, x + 1, y0 + 18, x + 3, y0 + 25, col)


def symbol(px, kind, cx, cy, col=PURPLE):
    for j, row in enumerate(SYM[kind]):
        for i, ch in enumerate(row):
            if ch == "#":
                px[(cx - 3 + i, cy - 3 + j)] = col


def console(px, c, r, wall, kind):
    x0, y0 = cell(c, r)
    art = tp.console("stepped")
    for (a, b), col in art.items():
        if col == tp.GREEN:
            col = tp.SCREEN        # the console's own symbol is replaced by the system's, drawn upright below
        xx, yy = TURN[wall](a, b)
        px[(x0 + xx, y0 + yy)] = col
    sx, sy = TURN[wall](17, 8)
    symbol(px, kind, x0 + sx, y0 + sy)


def core_cradle(px):
    """The Cybernetic Servicing Core: a gantry over a stand pad, two tiles wide against the south wall; walkable."""
    x0, y0 = cell(*CORE)
    w = 2 * T
    rect(px, x0 + 4, y0 + T - 8, x0 + w - 4, y0 + T - 1, OUTLINE)            # gantry base along the wall
    rect(px, x0 + 5, y0 + T - 7, x0 + w - 5, y0 + T - 2, "#2e3039")
    for gx in (x0 + 6, x0 + w - 12):                                          # gantry legs
        rect(px, gx, y0 + 8, gx + 6, y0 + T - 7, OUTLINE)
        rect(px, gx + 1, y0 + 9, gx + 5, y0 + T - 7, "#4a4d5a")
        rect(px, gx + 1, y0 + 9, gx + 2, y0 + T - 7, "#7a7f8e")
    cx, cy = x0 + T, y0 + 17
    for y in range(cy - 9, cy + 10):
        for x in range(cx - 9, cx + 10):
            d = ((x - cx) ** 2 + (y - cy) ** 2) ** .5
            if d < 9.5:
                px[(x, y)] = OUTLINE if d > 8.5 else (DEEP if d > 7.2 else "#2e3039" if d > 6 else "#4a4d5a")
    symbol(px, "medbay", cx, cy)


def clamp(px):
    """The Suit Dock's launch clamp at the bay's outer wall: a rail and a clamp frame; walkable."""
    x0, y0 = cell(*CLAMP)
    rect(px, x0 + 8, y0 + 14, x0 + T, y0 + 21, OUTLINE)
    rect(px, x0 + 9, y0 + 15, x0 + T, y0 + 20, "#2e3039")
    rect(px, x0 + 9, y0 + 15, x0 + T, y0 + 16, "#5f6576")
    for gx in range(x0 + 12, x0 + T - 2, 6):
        px[(gx, y0 + 17)] = PURPLE
        px[(gx + 1, y0 + 17)] = DEEP
    rect(px, x0 + 5, y0 + 9, x0 + 9, y0 + 26, OUTLINE)
    rect(px, x0 + 6, y0 + 10, x0 + 8, y0 + 25, "#4a4d5a")


def floor_layer(loadout, hull_px):
    check(loadout, hull_px)
    px = {}
    floor(px)
    for c, r, side in DOORS:
        door(px, c, r, side, DOOR)
    for c, r, side in AIRLOCKS:
        door(px, c, r, side, AIRLOCK)
    core_cradle(px)
    if loadout == "suit-dock":
        clamp(px)
    for _, c, r, wall, kind in CONSOLES + LOADOUT[loadout]:
        console(px, c, r, wall, kind)
    return px


def svg(px, under=""):
    r = "".join(f'<rect x="{x}" y="{y}" width="1" height="1" fill="{c}"/>' for (x, y), c in px.items())
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" '
            f'shape-rendering="crispEdges">{under}{r}</svg>')


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    h = hull.build(lights=True)
    hull_px = set(h.lv)
    hull_svg = h.svg()
    inner = hull_svg[hull_svg.index(">") + 1:hull_svg.rindex("</svg>")]
    for lo in LOADOUT:
        px = floor_layer(lo, hull_px)
        open(os.path.join(out, f"floor-{lo}.svg"), "w").write(svg(px))
        open(os.path.join(out, f"plan-{lo}.svg"), "w").write(svg(px, inner))
    print("checks passed; plans written")
