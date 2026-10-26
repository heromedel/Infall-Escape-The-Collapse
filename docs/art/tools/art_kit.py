"""Shared drawing kit for Infall ship hulls.

A hull is a list of parts drawn back to front. Every part is built in the same five stages, so any stage can be
exported on its own to review the process:
  1 outline, 2 fill, 3 shade, 4 highlight, 5 details.
Ships face up (nose at the top). Light comes from the upper left.
"""
import math

STAGE_NAMES = {1: "outline", 2: "fill", 3: "shade", 4: "highlight", 5: "details"}
LIGHT = (-0.6, -0.8)   # direction the light comes FROM (upper left), unit vector
INK = "#1b2230"        # outline colour: deep blue-black, softer than pure black


# ---------- colour helpers ----------

def rgb(hex_colour):
    h = hex_colour.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def shade(hex_colour, k):
    """k < 1 darkens, k > 1 lightens toward white."""
    r, g, b = rgb(hex_colour)
    if k <= 1:
        return "#%02x%02x%02x" % tuple(int(v * k) for v in (r, g, b))
    t = min(1.0, k - 1)
    return "#%02x%02x%02x" % tuple(int(v + (255 - v) * t) for v in (r, g, b))


# ---------- geometry helpers ----------

def mirror_x(points, cx):
    return [(2 * cx - x, y) for x, y in points]


def symmetric(half, cx):
    """Closes a left half-outline (top to bottom) with its mirror image (bottom to top)."""
    right = [pt for pt in mirror_x(half, cx)[::-1] if abs(pt[0] - cx) > 0.01]
    return half + right


def rounded_path(points, radius):
    """Closed path through a polygon with each corner rounded.

    radius is one number or a list per corner; 0 keeps a sharp corner. Rounded corners give the soft,
    clean look of doing-well Terran ships.
    """
    n = len(points)
    radii = radius if isinstance(radius, (list, tuple)) else [radius] * n
    cmds = []
    for i in range(n):
        p0, p1, p2 = points[i - 1], points[i], points[(i + 1) % n]
        r = radii[i]
        d1 = math.dist(p0, p1)
        d2 = math.dist(p1, p2)
        r = min(r, d1 / 2, d2 / 2)
        if r <= 0:
            a = b = p1
        else:
            a = (p1[0] + (p0[0] - p1[0]) * r / d1, p1[1] + (p0[1] - p1[1]) * r / d1)
            b = (p1[0] + (p2[0] - p1[0]) * r / d2, p1[1] + (p2[1] - p1[1]) * r / d2)
        cmds.append(("M" if i == 0 else "L") + f"{a[0]:.1f},{a[1]:.1f}")
        if r > 0:
            cmds.append(f"Q{p1[0]:.1f},{p1[1]:.1f} {b[0]:.1f},{b[1]:.1f}")
    return " ".join(cmds) + " Z"


# ---------- the part builder ----------

class Hull:
    """Collects defs and parts, and writes the SVG for a chosen stage."""

    def __init__(self, width, height, title):
        self.width, self.height, self.title = width, height, title
        self.parts = []          # (part_id, dict of stage -> svg fragments)
        self.defs = []
        self.extra_defs_ids = set()
        self.mounts = []         # weapon mount data: invisible spots, weapons are separate art

    def add_def(self, def_id, svg):
        if def_id not in self.extra_defs_ids:
            self.extra_defs_ids.add(def_id)
            self.defs.append(svg)

    def plate(self, part_id, path_d, base, *, bevel=5, outline=2.4, gloss=True, details="", shadow=0):
        """One hull plate: outline, flat fill, shading and highlights all clipped to the plate's own shape.

        bevel: width of the lit and shaded edge bands. shadow: offset of the soft shadow the plate casts on the
        parts beneath it (0 for none).
        """
        clip_id = f"{part_id}-clip"
        self.add_def(clip_id, f'<clipPath id="{clip_id}"><path d="{path_d}"/></clipPath>')
        lx, ly = LIGHT
        b = bevel
        stages = {}
        stages[1] = [f'<path class="outline" d="{path_d}" fill="none" stroke="{INK}" stroke-width="{outline}" '
                     f'stroke-linejoin="round"/>']
        cast = ""
        if shadow:
            cast = (f'<path class="cast-shadow" d="{path_d}" transform="translate({-lx * shadow:.1f},{-ly * shadow:.1f})" '
                    f'fill="#0b0f18" opacity=".45" filter="url(#soft)"/>')
        stages[2] = [f'<path class="fill" d="{path_d}" fill="{base}"/>']
        # Shade: a body gradient (lit upper left, dark lower right), then a dark band on edges facing away from
        # the light, made by stroking the plate's outline shifted toward the light and keeping what falls inside.
        grad_id = f"{part_id}-body"
        self.add_def(grad_id,
                     f'<linearGradient id="{grad_id}" x1="0" y1="0" x2="1" y2="1">'
                     f'<stop offset="0" stop-color="{shade(base, 1.10)}"/>'
                     f'<stop offset=".55" stop-color="{base}"/>'
                     f'<stop offset="1" stop-color="{shade(base, .80)}"/></linearGradient>')
        stages[3] = [f'<g class="shade" clip-path="url(#{clip_id})">'
                     f'<path d="{path_d}" fill="url(#{grad_id})"/>'
                     f'<path d="{path_d}" transform="translate({lx * b:.1f},{ly * b:.1f})" fill="none" '
                     f'stroke="{shade(base, .62)}" stroke-width="{b * 2.2:.1f}" opacity=".75"/>'
                     f'</g>']
        # Highlight: the same trick shifted away from the light gives a bright band on edges facing it, plus a
        # thin specular lip just inside the outline.
        hl = [f'<g class="highlight" clip-path="url(#{clip_id})">'
              f'<path d="{path_d}" transform="translate({-lx * b:.1f},{-ly * b:.1f})" fill="none" '
              f'stroke="{shade(base, 1.55)}" stroke-width="{b * 2.0:.1f}" opacity=".7"/>'
              f'<path d="{path_d}" transform="translate({-lx * b * .35:.1f},{-ly * b * .35:.1f})" fill="none" '
              f'stroke="#ffffff" stroke-width="{b * .55:.1f}" opacity=".55"/>']
        if gloss:
            hl.append(f'<path d="{path_d}" fill="url(#gloss)"/>')
        hl.append('</g>')
        stages[4] = hl
        stages[5] = [f'<g class="details" clip-path="url(#{clip_id})">{details}</g>'] if details else []
        self.parts.append((part_id, stages, cast))

    def raw(self, part_id, stage_svgs):
        """A part drawn by hand: stage_svgs maps stage number to svg text."""
        self.parts.append((part_id, {k: [v] for k, v in stage_svgs.items()}, ""))

    def mount(self, mount_id, x, y, weapon, slide):
        """A weapon mount: only a spot. The weapon's own art is drawn there by the game."""
        self.mounts.append((mount_id, x, y, weapon, slide))

    def svg(self, stage=5, show_mounts=False, background=None):
        body = []
        for part_id, stages, cast in self.parts:
            g = [f'<g id="{part_id}">']
            if stage >= 3 and cast:
                g.append(cast)
            # stage 1 shows outlines only; later stages draw fill etc. under the outline
            for s in range(2, stage + 1):
                g.extend(stages.get(s, []))
            g.extend(stages.get(1, []))
            g.append("</g>")
            body.append("\n".join(g))
        mounts = ['<g id="weapon-mounts" display="none">']
        for mount_id, x, y, weapon, slide in self.mounts:
            mounts.append(f'<circle id="{mount_id}" cx="{x}" cy="{y}" r="3" data-weapon="{weapon}" '
                          f'data-slide="{slide}"/>')
        mounts.append("</g>")
        overlay = ""
        if show_mounts:
            o = ['<g id="mount-preview">']
            for mount_id, x, y, weapon, slide in self.mounts:
                o.append(f'<circle cx="{x}" cy="{y}" r="7" fill="none" stroke="#e8453c" stroke-width="2"/>'
                         f'<line x1="{x - 11}" y1="{y}" x2="{x + 11}" y2="{y}" stroke="#e8453c" stroke-width="1.5"/>'
                         f'<line x1="{x}" y1="{y - 11}" x2="{x}" y2="{y + 11}" stroke="#e8453c" stroke-width="1.5"/>'
                         f'<text x="{x + (14 if x > self.width / 2 else -14)}" y="{y + 4}" font-size="11" '
                         f'font-family="sans-serif" fill="#e8453c" '
                         f'text-anchor="{"start" if x > self.width / 2 else "end"}">{weapon}</text>')
            o.append("</g>")
            overlay = "".join(o)
        bg = f'<rect width="100%" height="100%" fill="{background}"/>' if background else ""
        return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {self.width} {self.height}" width="{self.width}" height="{self.height}">
<title>{self.title}</title>
<defs>
  <filter id="soft" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="3"/></filter>
  <filter id="glow" x="-100%" y="-100%" width="300%" height="300%"><feGaussianBlur stdDeviation="3"/></filter>
  <linearGradient id="gloss" x1="0" y1="0" x2="0.35" y2="1">
    <stop offset="0" stop-color="#fff" stop-opacity=".18"/>
    <stop offset=".4" stop-color="#fff" stop-opacity="0"/>
  </linearGradient>
  {"".join(self.defs)}
</defs>
{bg}
<g id="hull-art">
{chr(10).join(body)}
</g>
{"".join(mounts)}
{overlay}
</svg>
'''
