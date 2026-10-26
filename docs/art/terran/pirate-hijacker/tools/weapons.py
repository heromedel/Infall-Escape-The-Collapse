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
    for name, body in {"twinshot": twinshot(), "sporewing": sporewing_c()}.items():
        open(os.path.join(out, f"{name}.svg"), "w").write(file(body))
    print("saved weapons")
