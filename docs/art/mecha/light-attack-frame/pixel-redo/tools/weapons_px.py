"""The Mecha frame's weapons in the Mecha pixel style, and the armed previews.

Usage: python3 weapons_px.py OUT_DIR
Writes ds-st-hull-laser.svg (twin barrels, pointing up, its mount point at the base centre), battlesuit-laser.svg (the
laser battlesuit: heromedel's HalfMech crew sprite with an arm laser and a jump pack) and the armed previews
armed-hull-laser.svg / armed-suit-dock.svg (the plan view of each loadout, standard frame, with its weapon at mount 4, slid out past
the hull's edge; the suit shown just launched, off the starboard bow). Sleek banded metal as on the hull; purple only at the emitters and thrusters.
"""
import os, sys
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import hull_bc_sleek as hull   # noqa: E402
import floor_bc               # noqa: E402
from pixel_svg import paths   # noqa: E402

RAMP = hull.RAMP
PURPLE, DEEP, PALE = "#aa28eb", "#5a128c", "#ebe1fa"
CREW = os.path.join(HERE, "..", "..", "..", "crew", "mecha-crew-sheet.png")


def laser():
    """DS-ST Hull Laser, 15 x 30, pointing up: a squat housing and two heavy barrels, one per shot."""
    px = {}
    W_, H_ = 15, 30
    for y in range(18, 30):                      # housing
        for x in range(0, 15):
            if (x, y) in ((0, 18), (14, 18), (0, 29), (14, 29)):
                continue
            edge = x in (0, 14) or y in (18, 29) or (x in (1, 13) and y in (18, 29))
            px[(x, y)] = RAMP[0] if edge else RAMP[6] if x == 1 or y == 19 else RAMP[4] if x < 7 else RAMP[3]
    for x in range(3, 12):
        px[(x, 23)] = RAMP[1]                    # a groove across the housing
    for bx in (2, 9):                            # barrels
        for y in range(2, 19):
            for x in range(bx, bx + 4):
                edge = x in (bx, bx + 3) or y == 2
                px[(x, y)] = RAMP[0] if edge else RAMP[6] if x == bx + 1 else RAMP[3]
        for x in range(bx + 1, bx + 3):          # emitters at the muzzles
            px[(x, 3)] = PALE
            px[(x, 4)] = PURPLE
            px[(x, 5)] = DEEP
    return px, W_, H_, (7, 22)                   # mount point in the housing, which stays under the hull


def battlesuit():
    """The laser battlesuit, 35 x 35: the HalfMech (walk-down frame of heromedel's crew sheet) inside its suit, a laser
    on its right arm (viewer's left); its jump pack sits on its back, out of sight from above."""
    im = Image.open(CREW).convert("RGBA")
    px = {}
    for y in range(35):
        for x in range(35):
            r, g, b, a = im.getpixel((x, y))
            if a > 128:
                px[(x, y)] = f"#{r:02x}{g:02x}{b:02x}"
    xs = [x for x, _ in px]
    lx = min(xs) - 1                             # the arm laser along the right forearm, pointing forward (up)
    for y in range(9, 21):
        for x in range(lx, lx + 3):
            px[(x, y)] = RAMP[0] if x in (lx, lx + 2) or y == 9 else RAMP[5]
    px[(lx + 1, 10)] = PALE
    px[(lx + 1, 11)] = PURPLE
    return px, 35, 35, (17, 30)


def svg(px, w, h):
    r = paths(px)
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" shape-rendering="crispEdges">{r}</svg>'


def armed(plan_px, hull_px, weapon, mount, under=True):
    """Place a weapon on a mount. Under the hull (as when it has slid out): only the part past the hull's edge shows."""
    px, w, h, (ax, ay) = weapon
    mx, my = mount
    out = dict(plan_px)
    for (x, y), c in px.items():
        p = (mx + x - ax, my + y - ay)
        if not (under and p in hull_px):
            out[p] = c
    return out


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    L, B = laser(), battlesuit()
    open(os.path.join(out, "ds-st-hull-laser.svg"), "w").write(svg(*L[:3]))
    open(os.path.join(out, "battlesuit-laser.svg"), "w").write(svg(*B[:3]))
    h = hull.build(lights=True)
    mount4 = hull.mounts(h)[3][:2]
    hull_px = {p: hull.RAMP[l] for p, l in h.lv.items()}
    hull_px.update(h.glow)
    for lo, weapon in (("hull-laser", L), ("suit-dock", B)):
        plan = dict(hull_px)
        plan.update(floor_bc.floor_layer(lo, set(h.lv), "standard"))
        if lo == "hull-laser":
            a = armed(plan, set(h.lv), weapon, mount4)
        else:   # the suit is launched, not mounted: shown in clear space off the starboard bow
            a = armed(plan, set(h.lv), weapon, (318, 74), under=False)
        r = paths({(x, y): c for (x, y), c in a.items() if 0 <= x < hull.W and 0 <= y < hull.H})
        open(os.path.join(out, f"armed-{lo}.svg"), "w").write(
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {hull.W} {hull.H}" width="{hull.W}" height="{hull.H}" shape-rendering="crispEdges">{r}</svg>')
    print("weapons and armed previews written; mount 4 at", mount4)
