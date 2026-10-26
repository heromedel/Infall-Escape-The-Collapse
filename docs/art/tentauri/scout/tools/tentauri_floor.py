"""Tentauri scout floor plan: two rooms, ten systems, two airlocks; biomechanical, so no conduits.

Usage: python3 tentauri_floor.py HULL_SVG OUT_DIR
Writes floor.svg (the floor layer), armed-preview.svg (hull with both Defense Lasers mounted) and plan.svg
(armed hull + floor). The plan shows the ship intact and powered.
"""
import base64
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tentauri_weapons as tw  # noqa: E402

GLYPHS = os.environ.get("GLYPH_DIR", os.path.join(HERE, "..", "..", "..", "terran", "outrider", "floor-layout-tests", "tools"))
sys.path.insert(0, GLYPHS)
from floor import glyph  # noqa: E402  (shared console symbols)

T = 35
CX = 170
X0, Y0 = CX - 2.5 * T, 110
W, H = 340, 380

PLATE = "#7aa3a8"
FLOOR = "#eaf0f1"
FLOOR_LINE = "#c9d8db"
WALL = "#24485a"
DOOR = "#7fe0dc"
AIRLOCK = "#f0a99f"
DESK = "#f6f8f9"
DESK_EDGE = "#7aa3a8"
SCREEN = "#1f3442"
SYMBOL = "#f39a86"     # the ship's coral: not green (powered state) and not red (a cut-off system)

ROOMS = [("forward", 0, 0, 5, 3), ("rear", 1, 3, 3, 2)]
CONSOLES = [("Sensors", 1, 0, "sensors"), ("Piloting", 2, 0, "piloting"), ("Shields", 3, 0, "shields"),
            ("Weapons A", 0, 1, "weapons"), ("Weapons B", 4, 1, "weapons"), ("Engines", 0, 2, "engines"),
            ("Doors", 4, 2, "doors"), ("Life Support", 1, 3, "life"), ("Medbay", 3, 3, "medbay"),
            ("Supershield Generator", 2, 4, "supershield")]
DOORS = [(2, 2, "s")]
AIRLOCKS = [(1, 4, "w"), (3, 4, "e")]


def cell(c, r):
    return X0 + c * T, Y0 + r * T


def room_of(c, r):
    for rid, rc, rr, w, h in ROOMS:
        if rc <= c < rc + w and rr <= r < rr + h:
            return rid
    return None


def check():
    """No console on a door tile; every console inside a room."""
    step = {"n": (0, -1), "s": (0, 1), "w": (-1, 0), "e": (1, 0)}
    tiles = set()
    for c, r, side in DOORS + AIRLOCKS:
        dc, dr = step[side]
        tiles |= {(c, r), (c + dc, r + dr)}
    blocked = [n for n, c, r, _ in CONSOLES if (c, r) in tiles]
    outside = [n for n, c, r, _ in CONSOLES if room_of(c, r) is None]
    assert not blocked and not outside, (blocked, outside)


def supershield_glyph(x, y, colour):
    return (f'<path d="M{x - 7},{y + 3} Q{x},{y - 9} {x + 7},{y + 3}" fill="none" stroke="{colour}" stroke-width="2"/>'
            f'<path d="M{x - 4.5},{y + 5} Q{x},{y - 3} {x + 4.5},{y + 5}" fill="none" stroke="{colour}" stroke-width="1.6"/>'
            f'<path d="M{x},{y + 1} l2,2 l-2,2 l-2,-2 Z" fill="{colour}"/>')


sys.path.insert(0, os.path.join(HERE, "..", "..", ".."))
from palette import TENTAURI_POWER_PINK  # noqa: E402

# the powered symbol: the scout is an enemy encounter (Ship Designs), and a ship fighting the player shows its race's
# power colour (palette.md); the game recolours it by who controls the ship
POWERED = TENTAURI_POWER_PINK
ORGAN = "#7fe0dc"
ORGAN_EDGE = "#24485a"



def organ_symbol(kind, x, y, k=.62):
    if kind == "supershield":
        return f'<g transform="translate({x},{y}) scale({k / .78:.2f}) translate({-x},{-y})">{supershield_glyph(x, y, POWERED)}</g>'
    return f'<g transform="translate({x},{y}) scale({k}) translate({-x},{-y})">{glyph(kind, x, y, POWERED)}</g>'


def bulb(x, y, r=8.5):
    """The organ's bulb: a dark lens with a soft green glow, the look heromedel picked."""
    return (f'<circle cx="{x}" cy="{y}" r="{r + 3}" fill="{POWERED}" opacity=".25" filter="url(#tw-glow)"/>'
            f'<circle cx="{x}" cy="{y}" r="{r}" fill="{SCREEN}" stroke="{ORGAN_EDGE}" stroke-width="1.6"/>')


def organ_tendril(name, c, r, kind):
    """A short curled tendril rising from a soft pad, its bulb showing the system's symbol."""
    x, y = cell(c, r)
    px, py = x + T / 2, y + T - 9
    bx, by = x + T / 2 + 3, y + 11
    stalk = f"M{px - 2},{py} C{px - 13},{py - 5} {px - 11},{py - 15} {px - 2},{py - 15} C{px + 6},{py - 15} {px + 6},{by + 10} {bx},{by + 6}"
    return (f'<g class="system" data-name="{name}">'
            f'<ellipse cx="{px}" cy="{py + 2}" rx="11" ry="5.5" fill="{ORGAN}" stroke="{ORGAN_EDGE}" stroke-width="1.3"/>'
            f'<path d="{stalk}" fill="none" stroke="{ORGAN_EDGE}" stroke-width="5.6" stroke-linecap="round"/>'
            f'<path d="{stalk}" fill="none" stroke="{ORGAN}" stroke-width="3.4" stroke-linecap="round"/>'
            f'{bulb(bx, by)}{organ_symbol(kind, bx, by)}</g>')


def organ_siphon(name, c, r, kind):
    """A squat siphon rising from a soft pad, its rounded mouth showing the system's symbol."""
    x, y = cell(c, r)
    cx = x + T / 2
    return (f'<g class="system" data-name="{name}">'
            f'<ellipse cx="{cx}" cy="{y + T - 7}" rx="12" ry="5" fill="{ORGAN}" stroke="{ORGAN_EDGE}" stroke-width="1.3"/>'
            f'<path d="M{cx - 7},{y + T - 8} C{cx - 9},{y + 20} {cx - 9},{y + 16} {cx - 8},{y + 13} L{cx + 8},{y + 13} '
            f'C{cx + 9},{y + 16} {cx + 9},{y + 20} {cx + 7},{y + T - 8} Z" fill="{ORGAN}" stroke="{ORGAN_EDGE}" stroke-width="1.3"/>'
            f'{bulb(cx, y + 12, 9)}{organ_symbol(kind, cx, y + 12, .66)}</g>')


def organ_grasp(name, c, r, kind):
    """Three short fingers rising from a soft pad, cupping an orb that shows the system's symbol."""
    x, y = cell(c, r)
    cx = x + T / 2
    fingers = "".join(f'<path d="M{cx + dx},{y + T - 8} C{cx + dx * 1.9},{y + 22} {cx + dx * 1.8},{y + 12} {cx + dx * .9},{y + 6}" '
                      f'fill="none" stroke="{ORGAN_EDGE}" stroke-width="5" stroke-linecap="round"/>'
                      f'<path d="M{cx + dx},{y + T - 8} C{cx + dx * 1.9},{y + 22} {cx + dx * 1.8},{y + 12} {cx + dx * .9},{y + 6}" '
                      f'fill="none" stroke="{ORGAN}" stroke-width="3" stroke-linecap="round"/>' for dx in (-6, 6))
    return (f'<g class="system" data-name="{name}">'
            f'<ellipse cx="{cx}" cy="{y + T - 7}" rx="11" ry="5" fill="{ORGAN}" stroke="{ORGAN_EDGE}" stroke-width="1.3"/>'
            f'{fingers}{bulb(cx, y + 14, 8.5)}{organ_symbol(kind, cx, y + 14)}</g>')


def _pad(cx, y, rx=11):
    return f'<ellipse cx="{cx}" cy="{y}" rx="{rx}" ry="5" fill="{ORGAN}" stroke="{ORGAN_EDGE}" stroke-width="1.3"/>'


def _stroke(d, w=5.2, inner=3.2, colour=None):
    return (f'<path d="{d}" fill="none" stroke="{ORGAN_EDGE}" stroke-width="{w}" stroke-linecap="round"/>'
            f'<path d="{d}" fill="none" stroke="{colour or ORGAN}" stroke-width="{inner}" stroke-linecap="round"/>')


def organ_trigger(name, c, r, kind):
    """Weapons: a hooked tendril with a guard ring, like a trigger grip."""
    x, y = cell(c, r)
    cx, base = x + T / 2, y + T - 7
    hook = f"M{cx - 3},{base} C{cx - 4},{y + 22} {cx + 9},{y + 22} {cx + 8},{y + 14}"
    ring = (f'<ellipse cx="{cx - 3}" cy="{base - 9}" rx="5.5" ry="4" fill="none" stroke="{ORGAN_EDGE}" stroke-width="3.4"/>'
            f'<ellipse cx="{cx - 3}" cy="{base - 9}" rx="5.5" ry="4" fill="none" stroke="{CORAL}" stroke-width="1.6"/>')
    return f'<g class="system" data-name="{name}">{_pad(cx, base)}{ring}{_stroke(hook)}{bulb(cx + 6, y + 12, 8)}{organ_symbol(kind, cx + 6, y + 12, .58)}</g>'


def organ_cradle(name, c, r, kind):
    """Medbay: a low cradle pod, like a bed, with the display orb at its head."""
    x, y = cell(c, r)
    cx = x + T / 2
    pod = (f'<path d="M{cx - 13},{y + 24} Q{cx - 14},{y + T - 4} {cx},{y + T - 4} Q{cx + 14},{y + T - 4} {cx + 13},{y + 24} '
           f'Q{cx},{y + 19} {cx - 13},{y + 24} Z" fill="{ORGAN}" stroke="{ORGAN_EDGE}" stroke-width="1.3"/>'
           f'<path d="M{cx - 8},{y + 26} Q{cx},{y + 23} {cx + 8},{y + 26}" fill="none" stroke="{ORGAN_EDGE}" '
           f'stroke-width="1" opacity=".6"/>')
    return f'<g class="system" data-name="{name}">{pod}{bulb(cx, y + 12, 8.5)}{organ_symbol(kind, cx, y + 12)}</g>'


def organ_hood(name, c, r, kind):
    """Shields: a curved membrane hood standing behind the orb, something that covers and protects."""
    x, y = cell(c, r)
    cx = x + T / 2
    hood = (f'<path d="M{cx - 14},{y + 22} Q{cx - 16},{y + 2} {cx},{y + 2} Q{cx + 16},{y + 2} {cx + 14},{y + 22} '
            f'Q{cx},{y + 15} {cx - 14},{y + 22} Z" fill="{ORGAN}" stroke="{ORGAN_EDGE}" stroke-width="1.3" opacity=".95"/>'
            + "".join(f'<path d="M{cx + dx},{y + 6} Q{cx + dx * 1.2},{y + 12} {cx + dx * 1.1},{y + 19}" fill="none" '
                      f'stroke="{ORGAN_EDGE}" stroke-width=".8" opacity=".5"/>' for dx in (-8, 8)))
    return f'<g class="system" data-name="{name}">{_pad(cx, y + T - 7)}{hood}{_stroke(f"M{cx},{y + T - 8} L{cx},{y + 20}", 4.6, 2.6)}{bulb(cx, y + 15, 8)}{organ_symbol(kind, cx, y + 15, .58)}</g>'


def organ_pincers(name, c, r, kind):
    """Doors: two small pincers either side of the orb, opening and closing."""
    x, y = cell(c, r)
    cx = x + T / 2
    pins = "".join(_stroke(f"M{cx + s * 4},{y + T - 8} C{cx + s * 14},{y + 22} {cx + s * 14},{y + 8} {cx + s * 5},{y + 5}")
                   for s in (-1, 1))
    return f'<g class="system" data-name="{name}">{_pad(cx, y + T - 7)}{pins}{bulb(cx, y + 15, 8)}{organ_symbol(kind, cx, y + 15, .58)}</g>'


def organ_lungs(name, c, r, kind):
    """Life Support: a soft two-lobed sac, like lungs, with the orb between the lobes."""
    x, y = cell(c, r)
    cx = x + T / 2
    lobes = "".join(f'<ellipse cx="{cx + s * 10}" cy="{y + 20}" rx="4.6" ry="9" fill="{ORGAN}" stroke="{ORGAN_EDGE}" '
                    f'stroke-width="1.3" transform="rotate({s * 12} {cx + s * 10} {y + 20})"/>' for s in (-1, 1))
    return f'<g class="system" data-name="{name}">{_pad(cx, y + T - 6, 12)}{lobes}{bulb(cx, y + 13, 8.5)}{organ_symbol(kind, cx, y + 13)}</g>'


def organ_halo(name, c, r, kind):
    """Supershield Generator: a halo of small nodes around the orb, a projected field."""
    x, y = cell(c, r)
    cx, cy = x + T / 2, y + T / 2 - 1
    import math as _m
    nodes = "".join(f'<circle cx="{cx + 13 * _m.cos(a):.1f}" cy="{cy + 13 * _m.sin(a):.1f}" r="2.4" fill="{LAVENDER_NODE}" '
                    f'stroke="{ORGAN_EDGE}" stroke-width=".9"/>' for a in [i * _m.pi / 4 for i in range(8)])
    ring = f'<circle cx="{cx}" cy="{cy}" r="13" fill="none" stroke="{ORGAN}" stroke-width="2.2" opacity=".8"/>'
    return f'<g class="system" data-name="{name}">{ring}{nodes}{bulb(cx, cy, 8.5)}{organ_symbol(kind, cx, cy)}</g>'


def organ_iris(name, c, r, kind):
    """Doors: an iris of coral petals behind the orb, a valve that opens and closes."""
    x, y = cell(c, r)
    cx, cy = x + T / 2, y + 15
    petals = "".join(f'<path d="M{cx},{cy} Q{cx - 5},{cy - 9} {cx},{cy - 15} Q{cx + 5},{cy - 9} {cx},{cy} Z" '
                     f'fill="{CORAL}" stroke="{ORGAN_EDGE}" stroke-width="1.1" transform="rotate({a} {cx} {cy})"/>'
                     for a in (-100, -50, 0, 50, 100))
    return (f'<g class="system" data-name="{name}">{_pad(cx, y + T - 7)}{petals}'
            f'{_stroke(f"M{cx},{y + T - 8} L{cx},{cy + 6}", 4.6, 2.6)}{bulb(cx, cy, 8)}{organ_symbol(kind, cx, cy, .58)}</g>')


def organ_sac(name, c, r, kind):
    """Life Support: a round breathing sac under the orb, pleated like bellows."""
    x, y = cell(c, r)
    cx = x + T / 2
    sy = y + 24
    sac = (f'<ellipse cx="{cx}" cy="{sy}" rx="13" ry="8.5" fill="{ORGAN}" stroke="{ORGAN_EDGE}" stroke-width="1.3"/>'
           + "".join(f'<path d="M{cx + dx},{sy - 6} Q{cx + dx * 1.25},{sy} {cx + dx},{sy + 7}" fill="none" '
                     f'stroke="{ORGAN_EDGE}" stroke-width=".9" opacity=".55"/>' for dx in (-8, -4, 4, 8)))
    return f'<g class="system" data-name="{name}">{sac}{bulb(cx, y + 12, 8.5)}{organ_symbol(kind, cx, y + 12)}</g>'


def organ_nozzle(name, c, r, kind):
    """Engines: a squat siphon whose mouth flares wide at the base, like a thruster."""
    x, y = cell(c, r)
    cx, base = x + T / 2, y + T - 6
    flare = (f'<path d="M{cx - 5},{y + 15} C{cx - 6},{y + 22} {cx - 14},{base - 4} {cx - 15},{base} L{cx + 15},{base} '
             f'C{cx + 14},{base - 4} {cx + 6},{y + 22} {cx + 5},{y + 15} Z" fill="{ORGAN}" stroke="{ORGAN_EDGE}" stroke-width="1.3"/>'
             f'<ellipse cx="{cx}" cy="{base}" rx="15" ry="3" fill="{ORGAN}" stroke="{ORGAN_EDGE}" stroke-width="1.3"/>'
             f'<path d="M{cx - 9},{base - 4} Q{cx},{base - 7} {cx + 9},{base - 4}" fill="none" stroke="{CORAL}" stroke-width="1.6"/>')
    return f'<g class="system" data-name="{name}">{flare}{bulb(cx, y + 12, 8.5)}{organ_symbol(kind, cx, y + 12)}</g>'


def organ_bud(name, c, r, kind):
    """Medbay: a half-open bud, petals rising either side and behind, cupping the orb like a patient."""
    x, y = cell(c, r)
    cx = x + T / 2
    back = (f'<path d="M{cx - 6},{y + 20} C{cx - 7},{y + 8} {cx - 2},{y + 3} {cx},{y + 2} C{cx + 2},{y + 3} {cx + 7},{y + 8} '
            f'{cx + 6},{y + 20} Z" fill="{PINK}" stroke="{ORGAN_EDGE}" stroke-width="1.1"/>')
    side = "".join(f'<path d="M{cx},{y + T - 6} C{cx + s * 16},{y + 28} {cx + s * 17},{y + 12} {cx + s * 13},{y + 5} '
                   f'C{cx + s * 10},{y + 12} {cx + s * 6},{y + 18} {cx},{y + T - 6} Z" fill="{LAVENDER_NODE}" '
                   f'stroke="{ORGAN_EDGE}" stroke-width="1.2"/>' for s in (-1, 1))
    return (f'<g class="system" data-name="{name}">{_pad(cx, y + T - 5)}{back}{side}{bulb(cx, y + 19, 7.5)}'
            f'{organ_symbol(kind, cx, y + 19, .55)}</g>')


def organ_air_sacs(name, c, r, kind):
    """Life Support: a cluster of small air sacs, like a bunch of grapes, the orb set in a soft collar on top."""
    x, y = cell(c, r)
    cx = x + T / 2
    pts = [(-9, 27), (0, 29), (9, 27), (-12, 20), (12, 20), (-5, 22), (5, 22)]
    sacs = "".join(f'<circle cx="{cx + dx}" cy="{y + dy}" r="4.6" fill="{ORGAN}" stroke="{ORGAN_EDGE}" stroke-width="1.1"/>'
                   f'<circle cx="{cx + dx - 1.4}" cy="{y + dy - 1.4}" r="1.3" fill="#ffffff" opacity=".6"/>' for dx, dy in pts)
    collar = (f'<path d="M{cx - 7},{y + 24} L{cx - 9.5},{y + 17} A11.5,11.5 0 1 1 {cx + 9.5},{y + 17} L{cx + 7},{y + 24} Z" '
              f'fill="{ORGAN}" stroke="{ORGAN_EDGE}" stroke-width="1.3"/>')
    return f'<g class="system" data-name="{name}">{collar}{sacs}{bulb(cx, y + 12, 8.5)}{organ_symbol(kind, cx, y + 12)}</g>'


def organ_pipes(name, c, r, kind):
    """Engines: soft rounded tubes of different heights, open at the top, like pipe organs, the orb in front."""
    x, y = cell(c, r)
    cx = x + T / 2
    tubes = "".join(f'<path d="M{cx + dx - w},{y + 26} L{cx + dx - w},{y + top + w} A{w},{w} 0 0 1 {cx + dx + w},{y + top + w} '
                    f'L{cx + dx + w},{y + 26} Z" fill="{ORGAN}" stroke="{ORGAN_EDGE}" stroke-width="1.2"/>'
                    f'<ellipse cx="{cx + dx}" cy="{y + top + w - .5}" rx="{w - 1.6}" ry="1.6" fill="{ORGAN_EDGE}"/>'
                    for dx, top, w in [(-10, 13, 4), (10, 10, 4), (-4, 4, 4.2), (4, 7, 4.2)])
    return (f'<g class="system" data-name="{name}">{_pad(cx, y + T - 6, 14)}{tubes}{bulb(cx, y + 22, 7.5)}'
            f'{organ_symbol(kind, cx, y + 22, .55)}</g>')


def organ_carapace(name, c, r, kind):
    """Shields: a small domed carapace of plates raised on a short stand, the orb resting on top."""
    x, y = cell(c, r)
    cx, cy = x + T / 2, y + 22
    stand = (f'<ellipse cx="{cx}" cy="{y + T - 4}" rx="8" ry="3.4" fill="{ORGAN}" stroke="{ORGAN_EDGE}" stroke-width="1.2"/>'
             + _stroke(f"M{cx},{y + T - 5} L{cx},{cy + 4}", 4.6, 2.6))
    dome = f'<ellipse cx="{cx}" cy="{cy}" rx="14" ry="6.5" fill="{ORGAN}" stroke="{ORGAN_EDGE}" stroke-width="1.3"/>'
    plates = "".join(f'<path d="M{cx + dx - 3},{cy + dy} l1.5,-2.2 h3 l1.5,2.2 l-1.5,2.2 h-3 Z" fill="none" '
                     f'stroke="{ORGAN_EDGE}" stroke-width=".8" opacity=".6"/>' for dx, dy in ((-9, 0), (9, 0), (-3.5, 2.6), (3.5, 2.6)))
    return f'<g class="system" data-name="{name}">{stand}{dome}{plates}{bulb(cx, y + 12, 8.5)}{organ_symbol(kind, cx, y + 12)}</g>'


CORAL = "#f0a99f"
LAVENDER_NODE = "#c9c2f0"
PINK = "#f6c9c0"

ORGANS = {"tendril": organ_tendril, "siphon": organ_siphon, "grasp": organ_grasp, "trigger": organ_trigger,
          "cradle": organ_cradle, "hood": organ_hood, "pincers": organ_pincers, "lungs": organ_lungs,
          "halo": organ_halo, "iris": organ_iris, "sac": organ_sac, "nozzle": organ_nozzle, "bud": organ_bud,
          "air sacs": organ_air_sacs, "pipes": organ_pipes, "carapace": organ_carapace}
# each system's organ form hints at its role; the symbol stays the standard one
FORM_BY_SYSTEM = {"Piloting": "hood", "Weapons A": "trigger", "Weapons B": "trigger", "Sensors": "grasp",
                  "Medbay": "bud", "Shields": "carapace", "Engines": "pipes", "Doors": "iris",
                  "Life Support": "air sacs", "Supershield Generator": "halo"}


MIRRORED = {"Weapons B"}   # the starboard twin faces the other way (its crosshair symbol is symmetric)


def organ_by_role(name, c, r, kind):
    body = ORGANS[FORM_BY_SYSTEM[name]](name, c, r, kind)
    if name not in MIRRORED:
        return body
    mx = cell(c, r)[0] + T / 2
    return f'<g transform="translate({2 * mx},0) scale(-1,1)">{body}</g>'
STYLE = os.environ.get("ORGAN_STYLE", "by-role")   # one base per system, shaped by what it does

ON_WALL = .5        # an organ is half size against its wall, so crew stand and use it on the same tile
ON_WALL_SYMBOL = .8  # its symbol shrinks less, to stay legible


def organ_on_wall(name, c, r, kind):
    """The organ by role, half size and upright, slid against the wall of its tile (never turned)."""
    global organ_symbol
    x, y = cell(c, r)
    cx, mid = x + T / 2, y + T / 2
    side = wall_side(c, r)
    # the point on the wall it hangs from, and the organ's own edge that meets it (its box is about x 3-32, y 2-34)
    ax, ay = {"n": (cx, y + 1.5), "e": (x + T - 1.5, mid), "s": (cx, y + T - 1.5), "w": (x + 1.5, mid)}[side]
    ex, ey = {"n": (cx, y + 2), "e": (x + 32, mid), "s": (cx, y + 34), "w": (x + 1, mid)}[side]
    spots, real = [], organ_symbol
    organ_symbol = lambda k_, x_, y_, k=.62: (spots.append((k_, x_, y_, k)), "")[1]
    try:
        body = organ_by_role(name, c, r, kind)
    finally:
        organ_symbol = real
    if name in MIRRORED:
        spots = [(k_, 2 * cx - x_, y_, k) for k_, x_, y_, k in spots]
    syms = "".join(real(k_, ax + ON_WALL * (x_ - ex), ay + ON_WALL * (y_ - ey), k * ON_WALL_SYMBOL) for k_, x_, y_, k in spots)
    return (f'<g transform="translate({ax},{ay}) scale({ON_WALL}) translate({-ex},{-ey})">{body}</g>{syms}')


def wall_side(c, r):
    here = room_of(c, r)
    step = {"n": (0, -1), "w": (-1, 0), "e": (1, 0), "s": (0, 1)}
    for side in ("n", "w", "e", "s"):
        dc, dr = step[side]
        if room_of(c + dc, r + dr) != here:
            return side
    return "n"


def terminal(name, c, r, kind):
    x, y = cell(c, r)
    side = wall_side(c, r)
    angle = {"n": 0, "e": 90, "s": 180, "w": 270}[side]
    cx, cy = x + T / 2, y + T / 2
    desk = (f'<rect x="{x + 3}" y="{y + 2}" width="{T - 6}" height="17" rx="7" fill="{DESK}" stroke="{DESK_EDGE}" '
            f'stroke-width="1.2"/><rect x="{x + 6}" y="{y + 4}" width="{T - 12}" height="12" rx="5" fill="{SCREEN}"/>')
    off = {"n": (0, -7.5), "e": (7.5, 0), "s": (0, 7.5), "w": (-7.5, 0)}[side]
    sx, sy = cx + off[0], cy + off[1]
    sym = (supershield_glyph(sx, sy, SYMBOL) if kind == "supershield" else
           f'<g transform="translate({sx},{sy}) scale(.78) translate({-sx},{-sy})">{glyph(kind, sx, sy, SYMBOL)}</g>')
    return f'<g class="system" data-name="{name}"><g transform="rotate({angle} {cx} {cy})">{desk}</g>{sym}</g>'


def door(c, r, side, colour):
    x, y = cell(c, r)
    if side in ("n", "s"):
        yy = y if side == "n" else y + T
        return f'<rect x="{x + 9}" y="{yy - 3}" width="{T - 18}" height="6" rx="3" fill="{colour}" stroke="{WALL}" stroke-width="1"/>'
    xx = x if side == "w" else x + T
    return f'<rect x="{xx - 3}" y="{y + 9}" width="6" height="{T - 18}" rx="3" fill="{colour}" stroke="{WALL}" stroke-width="1"/>'


def floor_layer():
    check()
    out = []
    for _, c, r, w, h in ROOMS:
        x, y = cell(c, r)
        out.append(f'<rect x="{x - 4}" y="{y - 4}" width="{w * T + 8}" height="{h * T + 8}" rx="10" fill="{PLATE}"/>')
    for _, c, r, w, h in ROOMS:
        x, y = cell(c, r)
        out.append(f'<rect x="{x}" y="{y}" width="{w * T}" height="{h * T}" rx="6" fill="{FLOOR}"/>')
        for i in range(1, w):
            out.append(f'<line x1="{x + i * T}" y1="{y}" x2="{x + i * T}" y2="{y + h * T}" stroke="{FLOOR_LINE}"/>')
        for j in range(1, h):
            out.append(f'<line x1="{x}" y1="{y + j * T}" x2="{x + w * T}" y2="{y + j * T}" stroke="{FLOOR_LINE}"/>')
        out.append(f'<rect x="{x}" y="{y}" width="{w * T}" height="{h * T}" rx="6" fill="none" stroke="{WALL}" '
                   f'stroke-width="3.5"/>')
    out += [door(c, r, s, DOOR) for c, r, s in DOORS] + [door(c, r, s, AIRLOCK) for c, r, s in AIRLOCKS]
    draw = organ_on_wall if STYLE == "by-role" else ORGANS.get(STYLE, terminal)
    out += [draw(*k) for k in CONSOLES]
    return "".join(out)


def armed(hull_svg):
    """The hull with a Defense Laser at each fitted mount (weapons are separate art), slid out in the mount's slide
    direction and drawn under the hull, so only the part past the edge shows."""
    text = open(hull_svg).read()
    mounts = re.findall(r'<circle id="mount-[\w-]+" cx="([\d.]+)" cy="([\d.]+)" r="3" data-weapon="([^"]*)" '
                        r'data-slide="(\w+)"', text)
    step = {"left": (-12, 0), "right": (12, 0), "up": (0, -12), "down": (0, 12)}
    placed = "".join(f'<g transform="translate({float(x) + step[s][0]},{float(y) + step[s][1]})">{tw.segmented()}</g>'
                     for x, y, w, s in mounts if w)
    start = text.index(">", text.index("<svg")) + 1
    return text[:start] + f'{tw.defs()}{tw.defs2()}<g id="weapons-preview">{placed}</g>' + text[start:]


def svg(body, title):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">'
            f'<title>{title}</title>{tw.defs()}{body}</svg>\n')


if __name__ == "__main__":
    hull, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    armed_text = armed(hull)
    open(os.path.join(out, "armed-preview.svg"), "w").write(armed_text)
    open(os.path.join(out, "floor.svg"), "w").write(svg(floor_layer(), "Tentauri scout floor"))
    data = base64.b64encode(armed_text.encode()).decode()
    open(os.path.join(out, "plan.svg"), "w").write(svg(
        f'<image href="data:image/svg+xml;base64,{data}" x="0" y="0" width="{W}" height="{H}"/>{floor_layer()}',
        "Tentauri scout plan"))
    print("saved to", out)
