"""Floor layout test 3 for the SC-1 Outrider: test 2's rooms with a wheel of conduits.

Usage: python3 floor3.py HULL_SVG OUT_SVG

The wheel: a rim loop runs through every system room (so every system has two paths), and four spokes run from the
core to spread-out points on the rim (forward, port, starboard, aft). Before drawing, the script cuts every conduit
segment, then every pair, and checks which systems lose power, so the legend's claims are tested, not assumed.
"""
import itertools
import sys

import floor2 as base
from floor2 import centre, CORE_TILE, ON, CUT, SYSTEMS

TEST_2_LEGEND = base.legend

# rim: a closed loop through the tiles, listed in order; it passes the core on both sides through the core room
RIM = [(3, 3), (3, 2), (3, 1), (3, 0), (2, 0), (1, 0), (1, 1), (1, 2), (1, 3), (1, 4), (0, 4), (0, 5), (0, 6),
       (0, 7), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (1, 12), (2, 12), (3, 12), (3, 11), (3, 10), (3, 9),
       (3, 8), (3, 7), (3, 6), (3, 5), (3, 4), (3, 3)]
# spokes from the core tile to the rim
SPOKES = {
    "forward": [CORE_TILE, (2, 6), (2, 5), (2, 4), (2, 3), (2, 2), (2, 1), (1, 1)],
    "port": [CORE_TILE, (1, 7)],
    "starboard": [CORE_TILE, (3, 7)],
    "aft": [CORE_TILE, (2, 8), (2, 9), (2, 10), (2, 11), (2, 12)],
}
# the demo: two cuts at once, one on the rim and one on the forward spoke; every system stays powered
DEMO_CUTS = [((1, 3), (1, 4)), ((2, 4), (2, 5))]


def segments():
    """Every conduit segment between neighbouring tiles, as an unordered pair."""
    segs = set()
    for path in [RIM] + list(SPOKES.values()):
        for a, b in zip(path, path[1:]):
            segs.add(frozenset((a, b)))
    return segs


def powered(cuts):
    """Tiles the core still reaches when the given segments are cut."""
    live = segments() - {frozenset(c) for c in cuts}
    reach, todo = {CORE_TILE}, [CORE_TILE]
    while todo:
        t = todo.pop()
        for s in live:
            if t in s:
                (other,) = s - {t}
                if other not in reach:
                    reach.add(other)
                    todo.append(other)
    return reach


def unpowered_systems(cuts):
    reach = powered(cuts)
    return [name for name, c, r, _ in SYSTEMS if (c, r) not in reach]


def check_power():
    """Tests the wheel: no single cut unpowers anything; reports the worst pair; finds the fewest cuts that kill all."""
    segs = sorted(segments(), key=sorted)
    singles = [s for s in segs if unpowered_systems([tuple(s)])]
    assert not singles, f"a single cut unpowers a system: {singles}"
    worst_pair = max(len(unpowered_systems([tuple(a), tuple(b)])) for a, b in itertools.combinations(segs, 2))
    assert not unpowered_systems(DEMO_CUTS), "the demo cuts unpower a system"
    # the fewest cuts anywhere that unpower every system (checked up to 3 cuts; the core has 4 exits, so 4 always do)
    kill_all = 4
    for n in (1, 2, 3):
        if any(len(unpowered_systems([tuple(x) for x in combo])) == len(SYSTEMS)
               for combo in itertools.combinations(segs, n)):
            kill_all = n
            break
    return {"segments": len(segs), "worst pair": worst_pair, "cuts to kill all": kill_all}


def conduits():
    def path_d(points):
        return "M" + " L".join(f"{centre(c, r)[0]:.1f},{centre(c, r)[1]:.1f}" for c, r in points)

    def wire(points):
        d = path_d(points)
        return (f'<path d="{d}" fill="none" stroke="#0c1018" stroke-width="6" stroke-linejoin="round" '
                f'stroke-linecap="round"/>'
                f'<path d="{d}" fill="none" stroke="{ON}" stroke-width="2.2" stroke-linejoin="round" '
                f'stroke-linecap="round" filter="url(#cglow)"/>'
                f'<path d="{d}" fill="none" stroke="#e8fff2" stroke-width=".8" stroke-linejoin="round"/>')

    def split(points):
        """Breaks a path at the demo cuts, so each cut shows as a dead gap."""
        runs, run = [], [points[0]]
        for a, b in zip(points, points[1:]):
            if frozenset((a, b)) in {frozenset(c) for c in DEMO_CUTS}:
                runs.append(run)
                run = [b]
            else:
                run.append(b)
        runs.append(run)
        return [r for r in runs if len(r) > 1]

    out = []
    for path in [RIM] + list(SPOKES.values()):
        for run in split(path):
            out.append(wire(run))
    for a, b in DEMO_CUTS:
        (ax, ay), (bx, by) = centre(*a), centre(*b)
        mx, my = (ax + bx) / 2, (ay + by) / 2
        horiz = ay == by
        g1 = (mx - 5, my) if horiz else (mx, my - 5)
        g2 = (mx + 5, my) if horiz else (mx, my + 5)
        out.append(f'<path d="M{ax},{ay} L{g1[0]},{g1[1]} M{g2[0]},{g2[1]} L{bx},{by}" stroke="#0c1018" '
                   f'stroke-width="6"/>'
                   f'<path d="M{mx - 6},{my - 3} l5,2 l-4,2 l6,1 M{mx + 6},{my + 2} l-5,-1 l4,-2" stroke="{CUT}" '
                   f'stroke-width="1.5" fill="none"/>')
    # junctions where the spokes meet the rim
    for path in SPOKES.values():
        x, y = centre(*path[-1])
        out.append(f'<circle cx="{x}" cy="{y}" r="4.2" fill="#0c1018"/><circle cx="{x}" cy="{y}" r="2.4" fill="{ON}"/>')
    return "".join(out)


def legend(stats):
    return TEST_2_LEGEND(
        title="Floor layout test 3",
        ring_note="Conduit wheel: a rim through every system room, and four spokes from the core to the rim.",
        cut_note=f"Two cuts, one on the rim and one on a spoke: every system still has power. No single cut "
                 f"unpowers anything; two cuts lose at most {stats['worst pair']} systems; it takes "
                 f"{stats['cuts to kill all']} cuts to lose them all.")


def build(hull_svg):
    stats = check_power()
    base.conduits = conduits
    base.legend = lambda: legend(stats)
    svg = base.build(hull_svg)
    svg = svg.replace("SC-1 Outrider floor layout test 2", "SC-1 Outrider floor layout test 3")
    return svg, stats


if __name__ == "__main__":
    svg, stats = build(sys.argv[1])
    open(sys.argv[2], "w").write(svg)
    print("saved", sys.argv[2], stats)
