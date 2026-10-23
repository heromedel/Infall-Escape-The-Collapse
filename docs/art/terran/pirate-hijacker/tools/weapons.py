"""Weapon art for the Terran pirate cruiser: separate files, drawn around their mount point at (0, 0), pointing up.

Usage: python3 weapons.py OUT_DIR
Writes twinshot.svg and sporewing-a/b/c.svg (three Sporewing styles), plus a review sheet SVG.
The game places each at its hull mount; the previews in this folder do the same.
"""
import os
import sys

INK = "#1b2230"
STEEL = "#7c838d"
STEEL_LIGHT = "#a3aab4"
DARK = "#2b3037"
AZ_ROYAL = "#2547b8"
AZ_BLUE = "#3a8fe0"
AZ_SHEEN = "#6fd3f0"
AZ_DEEP = "#14286e"


def defs():
    return (f'<defs><linearGradient id="w-metal" x1="0" y1="0" x2="1" y2="0">'
            f'<stop offset="0" stop-color="{STEEL_LIGHT}"/><stop offset=".55" stop-color="{STEEL}"/>'
            f'<stop offset="1" stop-color="#5a616b"/></linearGradient>'
            f'<linearGradient id="w-chitin" x1="0" y1="0" x2="1" y2="1">'
            f'<stop offset="0" stop-color="{AZ_SHEEN}"/><stop offset=".4" stop-color="{AZ_BLUE}"/>'
            f'<stop offset="1" stop-color="{AZ_ROYAL}"/></linearGradient></defs>')


def twinshot():
    """Gat 2.1 Twinshot: a compact Terran turret block with two parallel laser barrels."""
    return (f'<g id="weapon-twinshot">'
            f'<rect x="-13" y="-14" width="26" height="28" rx="4" fill="url(#w-metal)" stroke="{INK}" stroke-width="1.5"/>'
            f'<rect x="-9" y="-10" width="18" height="10" rx="2" fill="{DARK}"/>'
            + "".join(f'<rect x="{x - 2.5}" y="-46" width="5" height="34" rx="1.5" fill="url(#w-metal)" '
                      f'stroke="{INK}" stroke-width="1.2"/><rect x="{x - 3.5}" y="-48" width="7" height="5" rx="1" '
                      f'fill="{DARK}" stroke="{INK}" stroke-width="1"/><circle cx="{x}" cy="-46" r="1.2" fill="#ff8f6b"/>'
                      for x in (-5, 5))
            + f'<circle cx="0" cy="6" r="3" fill="{DARK}" stroke="{STEEL_LIGHT}" stroke-width=".8"/></g>')


def terran_base():
    """The Terran hardpoint base every refitted weapon sits on."""
    return (f'<rect x="-14" y="-6" width="28" height="22" rx="4" fill="url(#w-metal)" stroke="{INK}" stroke-width="1.5"/>'
            f'<rect x="-10" y="10" width="20" height="3" rx="1" fill="{DARK}"/>')


def sporewing_a():
    """A sleek chitin missile pod with two wing vanes folded flat along it, seated in a Terran hardpoint base."""
    pod = (f'<path d="M0,-50 C9,-46 11,-26 10,-4 C9,8 5,14 0,16 C-5,14 -9,8 -10,-4 C-11,-26 -9,-46 0,-50 Z" '
           f'fill="url(#w-chitin)" stroke="{INK}" stroke-width="1.5"/>'
           + "".join(f'<path d="M-9,{y} Q0,{y + 4} 9,{y}" fill="none" stroke="{AZ_DEEP}" stroke-width="1"/>'
                     for y in (-30, -18, -6))
           + f'<path d="M-4,-44 Q-6,-20 -4,8" fill="none" stroke="#ffffff" stroke-width="2.4" opacity=".3"/>'
           f'<circle cx="0" cy="-44" r="3" fill="{AZ_DEEP}"/><circle cx="0" cy="-44" r="1.4" fill="{AZ_SHEEN}"/>')
    vanes = "".join(f'<path d="M{s * 9},-28 C{s * 18},-22 {s * 20},-4 {s * 15},8 L{s * 10},4 Z" fill="{AZ_ROYAL}" '
                    f'stroke="{INK}" stroke-width="1.2"/><path d="M{s * 11},-20 Q{s * 15},-8 {s * 13},2" fill="none" '
                    f'stroke="{AZ_SHEEN}" stroke-width=".9" opacity=".7"/>' for s in (-1, 1))
    return f'<g id="weapon-sporewing">{terran_base()}{vanes}{pod}</g>'


def sporewing_b():
    """A segmented organic tube on a Terran swivel mount: insect-like ring segments."""
    segs = "".join(f'<ellipse cx="0" cy="{y}" rx="{9 - i * .6:.1f}" ry="6" fill="url(#w-chitin)" stroke="{INK}" '
                   f'stroke-width="1.2"/>' for i, y in enumerate((4, -6, -16, -26, -36)))
    tip = f'<ellipse cx="0" cy="-45" rx="5" ry="6" fill="{AZ_DEEP}" stroke="{INK}" stroke-width="1.2"/>'
    return f'<g id="weapon-sporewing">{terran_base()}{segs}{tip}</g>'


def sporewing_c():
    """The Sporewing, refitted: two folded wing plates close into a launcher housing that opens to fire, seated
    neatly in a Terran hardpoint base. Its moth-like Azurethea origin shows in the wings and their eye-spots."""
    base = (f'<rect x="-16" y="0" width="32" height="18" rx="4" fill="url(#w-metal)" stroke="{INK}" stroke-width="1.5"/>'
            f'<rect x="-12" y="12" width="24" height="3" rx="1" fill="{DARK}"/>'
            f'<circle cx="-11" cy="5" r="1.3" fill="{DARK}"/><circle cx="11" cy="5" r="1.3" fill="{DARK}"/>')
    wings = "".join(f'<path d="M0,-50 C{s * 15},-42 {s * 17},-10 {s * 12},6 L0,4 Z" fill="url(#w-chitin)" '
                    f'stroke="{INK}" stroke-width="1.4"/><path d="M{s * 2},-40 Q{s * 11},-22 {s * 9},0" fill="none" '
                    f'stroke="{AZ_DEEP}" stroke-width="1"/>'
                    f'<ellipse cx="{s * 7}" cy="-14" rx="3" ry="4" fill="{AZ_DEEP}"/>'
                    f'<ellipse cx="{s * 7}" cy="-14" rx="1.5" ry="2" fill="{AZ_SHEEN}"/>' for s in (-1, 1))
    return (f'<g id="weapon-sporewing">{base}{wings}'
            f'<line x1="0" y1="-48" x2="0" y2="4" stroke="{INK}" stroke-width="1.4"/></g>')


def file(body, w=80, h=90, ox=40, oy=60):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{defs()}'
            f'<g transform="translate({ox},{oy})">{body}</g></svg>\n')


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    pieces = {"twinshot": twinshot(), "sporewing-a": sporewing_a(), "sporewing-b": sporewing_b(),
              "sporewing-c": sporewing_c()}
    for name, body in pieces.items():
        open(os.path.join(out, f"{name}.svg"), "w").write(file(body))
    cells = "".join(f'<g transform="translate({60 + i * 120},90) scale(1.6)">{b}</g>'
                    f'<text x="{60 + i * 120}" y="170" font-size="12" fill="#cfd6e2" text-anchor="middle" '
                    f'font-family="sans-serif">{n}</text>' for i, (n, b) in enumerate(pieces.items()))
    open(os.path.join(out, "weapon-options.svg"), "w").write(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="490" height="185">{defs()}'
        f'<rect width="100%" height="100%" fill="#434951"/>{cells}</svg>')
    print("saved weapons")
