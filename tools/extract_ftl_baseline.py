"""Extract FTL baseline numbers from unpacked vanilla data into markdown.

Usage: python3 extract_ftl_baseline.py <path to unpacked ftl.dat>/data > docs/reference/ftl-baseline.md
(prepend the hand-written header section of ftl-baseline.md)
"""
import re, sys, xml.etree.ElementTree as ET
D = sys.argv[1]

def load(name):
    t = open(f"{D}/{name}", encoding="utf-8", errors="replace").read()
    t = re.sub(r"<\?xml[^>]*\?>", "", t)
    t = re.sub(r"<!--.*?-->", "", t, flags=re.S)
    t = re.sub(r"</?FTL>", "", t)
    return ET.fromstring("<root>" + t + "</root>")

text = {}
for f in ("text_blueprints.xml",):
    for e in load(f).iter("text"):
        text[e.get("name")] = (e.text or "").strip()

def title(bp):
    t = bp.find("title")
    if t is None: return bp.get("name")
    return text.get(t.get("id"), t.text or bp.get("name")) if t.get("id") else (t.text or bp.get("name"))

def g(bp, tag, default=""):
    e = bp.find(tag)
    return (e.text or "").strip() if e is not None and e.text else default

bps = load("blueprints.xml")
dlc = load("dlcBlueprints.xml")
out = []
out.append("## Weapons\n")
out.append("Cooldown is in seconds (per charge for charge weapons). Missiles = missiles used per volley. SP = shield piercing. Beam length is in pixels. Fire and breach chances are per room hit.\n")
out.append("| Weapon | ID | Type | Damage | Shots | SP | Ion | Fire % | Breach % | Cooldown | Power | Missiles | Cost |")
out.append("|---|---|---|---|---|---|---|---|---|---|---|---|---|")
rows = []
for src in (bps, dlc):
    for w in src.iter("weaponBlueprint"):
        if not g(w, "cost"): continue
        shots = g(w, "shots") or ("beam" if g(w, "type") == "BEAM" else "1")
        if g(w, "type") == "BEAM": shots = "beam " + g(w, "length", "?")
        projs = w.find("projectiles")
        if projs is not None:   # flak: count the real (non-fake) projectiles
            shots = str(sum(int(p.get("count", "1")) for p in projs if p.get("fake") != "true"))
        if g(w, "chargeLevels"):
            shots = f"{shots} per charge, up to {g(w, 'chargeLevels')} charges"
        rows.append((g(w, "type"), title(w), w.get("name"), shots, g(w, "damage", "0"), g(w, "sp", "0"), g(w, "ion", "0"),
                     str(int(g(w, "fireChance", "0") or 0) * 10), str(int(g(w, "breachChance", "0") or 0) * 10),
                     g(w, "cooldown"), g(w, "power"), g(w, "missiles", "0"), g(w, "cost")))
for r in sorted(rows, key=lambda r: (r[0], int(r[12]))):
    out.append(f"| {r[1]} | {r[2]} | {r[0]} | {r[4]} | {r[3]} | {r[5]} | {r[6]} | {r[7]} | {r[8]} | {r[9]} | {r[10]} | {r[11]} | {r[12]} |")

out.append("\n## Drones\n")
out.append("| Drone | ID | Type | Power | Cost |\n|---|---|---|---|---|")
rows = []
for src in (bps, dlc):
    for d in src.iter("droneBlueprint"):
        if g(d, "cost"): rows.append((title(d), d.get("name"), g(d, "type"), g(d, "power"), g(d, "cost")))
for r in sorted(rows, key=lambda r: int(r[4])): out.append("| " + " | ".join(r) + " |")

out.append("\n## Systems\n")
out.append("Cost = price to buy the system at a store. Upgrade costs are scrap per level, from level 2 upward.\n")
out.append("| System | Start power | Max power | Cost | Upgrade costs |\n|---|---|---|---|---|")
for src in (bps, dlc):
    for s in src.iter("systemBlueprint"):
        ups = [l.text.strip() for l in s.iter("level")][: max(0, int(g(s, "maxPower", "1") or 1) - 1)]
        out.append(f"| {title(s)} | {g(s,'startPower')} | {g(s,'maxPower')} | {g(s,'cost','—')} | {', '.join(ups)} |")

out.append("\n## Crew\n")
out.append("| Race | ID | Cost |\n|---|---|---|")
for src in (bps, dlc):
    for c in src.iter("crewBlueprint"):
        if g(c, "cost"): out.append(f"| {title(c)} | {c.get('name')} | {g(c,'cost')} |")

out.append("\n## Augments\n")
out.append("| Augment | ID | Cost |\n|---|---|---|")
rows = []
for src in (bps, dlc):
    for a in src.iter("augBlueprint"):
        if g(a, "cost"): rows.append((title(a), a.get("name"), g(a, "cost")))
for r in sorted(rows, key=lambda r: int(r[2])): out.append("| " + " | ".join(r) + " |")

out.append("\n## Player ships (type A layouts)\n")
out.append("| Ship | ID | Hull | Starting reactor power | Starting weapons |\n|---|---|---|---|---|")
for src in (bps, dlc):
    for s in src.iter("shipBlueprint"):
        n = s.get("name")
        if not n.startswith("PLAYER_SHIP") or n.endswith(("_2", "_3")): continue
        h = s.find("health"); p = s.find("maxPower")
        ws = [w.get("name") for w in s.iter("weapon")]
        cls = s.find("class")
        nm = text.get(cls.get("id"), n) if cls is not None and cls.get("id") else (cls.text if cls is not None else n)
        out.append(f"| {nm} | {n} | {h.get('amount') if h is not None else ''} | {p.get('amount') if p is not None else ''} | {', '.join(ws)} |")

auto = load("autoBlueprints.xml")
out.append("\n## Enemy ship templates (base values before sector scaling)\n")
out.append("| Template | Hull | Base reactor power |\n|---|---|---|")
for s in auto.iter("shipBlueprint"):
    h = s.find("health"); p = s.find("maxPower")
    if h is None: continue
    out.append(f"| {s.get('name')} | {h.get('amount')} | {p.get('amount') if p is not None else ''} |")
print("\n".join(out))
