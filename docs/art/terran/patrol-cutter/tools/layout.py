"""The GATOS Patrol Cutter's rooms, from the Godot version's ship file (infall-godot/content/ships/patrol-cutter/
ship.xml), on the hull's pixel grid: 35 px tiles at 1x, tile (0, 0) centred on the hull's centre point. Every hull
concept is drawn around these rooms, never the other way round (docs/art/ship-art-process.md, rooms first)."""

TILE = 35
W, H = 300, 480                 # the hull canvas at 1x
CX, CY = W / 2, H / 2           # the centre of tile (0, 0)

ROOMS = [  # name, first tile, last tile
    ("Bridge", (-1, -4), (1, -3)),
    ("Shields room", (-2, -2), (-1, -1)),
    ("Corridor", (0, -2), (0, -1)),
    ("Medbay", (1, -2), (2, -1)),
    ("Core room", (-1, 0), (1, 1)),
    ("Port airlock", (-2, 0), (-2, 1)),
    ("Doors room", (2, 0), (2, 1)),
    ("Aft hall", (-1, 2), (1, 2)),
    ("Engine room", (-1, 3), (1, 4)),
]
WEAPONS = {3: "gat-2-1", 4: "gat-m1"}          # Patrol Cutter; the Checkpoint loadout fits gat-3-1 and gat-m2


def rect(first, last):
    """A room's pixel rectangle: x0, y0, x1, y1."""
    return (CX + (first[0] - .5) * TILE, CY + (first[1] - .5) * TILE,
            CX + (last[0] + .5) * TILE, CY + (last[1] + .5) * TILE)


def rooms_svg(stroke="#e8453c"):
    """The rooms as an overlay, for review sheets only."""
    out = []
    for name, a, b in ROOMS:
        x0, y0, x1, y1 = rect(a, b)
        out.append(f'<rect x="{x0}" y="{y0}" width="{x1 - x0}" height="{y1 - y0}" fill="none" stroke="{stroke}" '
                   f'stroke-width="1.5" stroke-dasharray="4 3"/>')
    return "".join(out)
