"""Crew portrait options for review: HalfMech cyborg kittens and mercenary Terran humans, as pixel grids.

Each portrait is rows of palette letters ('.' is clear). The sheet shows every option large, then at the sizes the
game draws crew tokens (a 25 px token on the ship, a 32 px token on the crew card), on the token's dark disc with
its ring, the way players will see them.

    python3 portraits.py OUT_DIR
"""
import sys
from PIL import Image, ImageDraw

# --- HalfMech kittens: 13 x 12, dark fur, Mecha power purple implants (heromedel's idea, GV 7D) -----------------

KITTEN_PALETTE = {
    "#": "#07060b",  # outline
    "R": "#6e5e94",  # rim light, so a black kitten reads on a dark token
    "Y": "#4d4662",  # fur lit
    "O": "#363045",  # fur
    "o": "#252030",  # fur shade
    "K": "#8a4e7e",  # inside the ears, dusky pink
    "W": "#57506a",  # muzzle, lighter than the fur so the face reads
    "N": "#b06a86",  # nose
    "M": "#5f6576",  # implant metal (the Mecha hull ramp's brightest)
    "m": "#3d414d",  # implant metal shade
    "P": "#aa28eb",  # Mecha power purple
    "p": "#5a128c",  # purple deep
    "L": "#ebe1fa",  # purple pale, the glow's core
    "G": "#5fe08a",  # green eye
    "B": "#5aa8ff",  # blue eye
    "V": "#c070ff",  # purple eye
    "H": "#ffffff",  # glint
    "e": "#07060b",  # pupil
}

# The kitten head: bigger eyes and a smaller muzzle than the adult GATOS head, ears up.
KITTENS = {
    "visor": [  # a thin purple visor across the eyes, like the mech suit's helmet; the eyes glow through it
        "..#.......#..",
        ".#R#.....#O#.",
        "#RK##...##KO#",
        "#RKO#####OKO#",
        "#RYOOOOOOOOo#",
        "#mMMMMMMMMMm#",
        "#pPLPpppPLPp#",
        "#RYOmmOmmOOo#",
        "#RYOOWWWOOOo#",
        "#RYOWWNWWOOo#",
        ".#oOOWWWOOo#.",
        "..#########..",
    ],
    "cyber eye": [  # one green eye, the other a purple implant in a metal ring, a seam down the cheek
        "..#.......#..",
        ".#R#.....#O#.",
        "#RK##...##KO#",
        "#RKO#####OKO#",
        "#RYOOOOOOMMo#",
        "#RY##OOOMmmM#",
        "#RYHe#OOMPLM#",
        "#RYGG#OOMPPM#",
        "#RYOOWWWOmMo#",
        "#RYOWWNWWOpo#",
        ".#oOOWWWOOp#.",
        "..#########..",
    ],
    "antenna ear": [  # blue eyes, one ear capped in metal with a purple light, a purple dot on the brow
        ".M........#..",
        ".MP#.....#O#.",
        "#Mm##...##KO#",
        "#RmO#####OKO#",
        "#RYOOOPOOOOo#",
        "#RY##OOO##Oo#",
        "#RYHe#O#He#o#",
        "#RYBB#O#BB#o#",
        "#RYOOWWWOOOo#",
        "#RYOWWNWWOOo#",
        ".#oOOWWWOOo#.",
        "..#########..",
    ],
    "jaw plate": [  # purple eyes, the muzzle a metal plate with glowing vents
        "..#.......#..",
        ".#R#.....#O#.",
        "#RK##...##KO#",
        "#RKO#####OKO#",
        "#RYOOOOOOOOo#",
        "#RY##OOO##Oo#",
        "#RYHe#O#He#o#",
        "#RYVV#O#VV#o#",
        "#RYOMMMMMOOo#",
        "#RYOMPmPMOOo#",
        ".#oOmMMMmOo#.",
        "..#########..",
    ],
    "purple tuft": [  # the pilot's purple hair as a tuft, green eyes, an implant line along one cheek
        "..#..pP...#..",
        ".#R#pPLp.#O#.",
        "#RK#pPPp##KO#",
        "#RKOO#p##OKo#",
        "#RYOOOOOOOOo#",
        "#RY##OOO##Oo#",
        "#RYHe#O#He#o#",
        "#RYGG#O#GG#o#",
        "#RYOOWWWOOPo#",
        "#RYOWWNWWOPo#",
        ".#oOOWWWOOp#.",
        "..#########..",
    ],
}

# --- Mercenary Terran humans: 15 x 15, head and shoulders ------------------------------------------------------

HUMAN_COMMON = {
    "#": "#14101a",  # outline
    "E": "#14101a",  # eyes
    "w": "#e8e2da",  # eye white glint
    "C": "#3f4a3a",  # jacket (olive)
    "c": "#2a3227",  # jacket shade
    "Z": "#7a6a52",  # collar, strap
    "T": "#c0c6cf",  # metal (earpiece, buckle)
    "R": "#c65a4a",  # scar
    "G": "#2fd0ff",  # visor or earpiece light
    "D": "#2a2a33",  # dark gear (cap, patch)
}
SKINS = {
    # S skin, s shade, m mouth, x stubble (the shade with a grey cast)
    "light": {"S": "#f0c8a0", "s": "#d39f78", "m": "#b07a5c", "x": "#b8a08c"},
    "tan": {"S": "#d49a6a", "s": "#b07a4e", "m": "#8a5a3a", "x": "#9a7a62"},
    "brown": {"S": "#9c6644", "s": "#7a4c30", "m": "#5a3420", "x": "#6e5040"},
    "deep": {"S": "#7c5036", "s": "#5e3a26", "m": "#43281a", "x": "#553a2c"},
}
HAIRS = {
    "black": {"H": "#3a3442", "h": "#221e29"},
    "brown": {"H": "#6a4428", "h": "#4a2e1a"},
    "red": {"H": "#b8542c", "h": "#86381c"},
    "blond": {"H": "#d8b060", "h": "#a8823c"},
    "grey": {"H": "#a8aab0", "h": "#7a7c84"},
    "white": {"H": "#e6e6ea", "h": "#b4b4bc"},
}

# Every face shares one template: a rounded head that narrows to the jaw, ears on both sides, brows over single dark
# eyes (a steady look), a nose shadow and a small mouth. The options change the hair, gear and marks around it.
HUMANS = {
    "buzz cut veteran": ([  # cropped hair, a scar through one brow, stubble, a flat steady mouth
        "....#######....",
        "...#hHHHHHh#...",
        "..#hHHHHHHHh#..",
        "..#HSSSSSSSs#..",
        "..#SSSSSSSSs#..",
        "..#ShhSSShRs#..",
        ".#sSSESSSERSs#.",
        ".#sSSSSsSSSSs#.",
        "..#SSSSsSSSs#..",
        "..#xSSmmmSSx#..",
        "...#xSSSSSx#...",
        "....#xxxxx#....",
        "...##sSSSs##...",
        ".#cCCZsssZCCc#.",
        "#cCCCCZCZCCCCc#",
    ], "tan", "brown"),
    "undercut with comm": ([  # hair swept over one side, the other shaved, a glowing earpiece, a smirk
        "....#######....",
        "...#HHHHHHh#...",
        "..#HHHHHHHHhh#.",
        "..#HHHHHSSShh#.",
        "..#HHHSSSSSsh#.",
        "..#HHhSSShhSs#.",
        ".#sHSESSSESSTG.",
        ".#sHSSSsSSSST#.",
        "..#HSSSsSSSs#..",
        "..#SSSmmmmSs#..",
        "...#SSSSSSs#...",
        "....#sssss#....",
        "...##sSSSs##...",
        ".#cCCZsssZCCc#.",
        "#cCCCCZCZCCCCc#",
    ], "light", "red"),
    "goggles up": ([  # goggles pushed up into the hair, an easy half grin
        "....#######....",
        "...#HHHHHHH#...",
        "..#hHHHHHHHh#..",
        "..#DGGDDDGGD#..",
        "..#DDDDDDDDD#..",
        "..#ShhSSShhs#..",
        ".#sSSESSSESSs#.",
        ".#sSSSSsSSSSs#.",
        "..#SSSSsSSSs#..",
        "..#SSSmmmmSs#..",
        "...#SSSSSSs#...",
        "....#sssss#....",
        "...##sSSSs##...",
        ".#cCCZsssZCCc#.",
        "#cCCCCZCZCCCCc#",
    ], "brown", "black"),
    "eyepatch": ([  # long hair framing the face, a patch and its strap over one eye, a firm mouth
        "....#######....",
        "...#HHHHHHH#...",
        "..#HHHHHHHHH#..",
        "..#HHSSSSSDH#..",
        ".#HHSSSSSDSHH#.",
        ".#HShhSSDDDsH#.",
        ".#HSSESSDDDSH#.",
        ".#HSSSSsSTSSH#.",
        ".#HHSSSsSSSHH#.",
        "..#HSSmmmSSH#..",
        "..#H#SSSSs#H#..",
        "..#H.#sss#.H#..",
        "..#H#sSSSs#H#..",
        ".#cCCZsssZCCc#.",
        "#cCCCCZCZCCCCc#",
    ], "deep", "black"),
    "grey vet": ([  # cropped grey hair, a short full beard and moustache, heavy brows
        "....#######....",
        "...#hHHHHHh#...",
        "..#HHHHHHHHH#..",
        "..#HSSSSSSSH#..",
        "..#SSSSSSSSs#..",
        "..#ShhSSShhs#..",
        ".#sSSESSSESSs#.",
        ".#sSSSSsSSSSs#.",
        "..#HSSSsSSSH#..",
        "..#HHHmmmHHH#..",
        "...#HHHHHHH#...",
        "....#hHHHh#....",
        "...##hhhhh##...",
        ".#cCCZhhhZCCc#.",
        "#cCCCCZCZCCCCc#",
    ], "light", "grey"),
}


def check(name: str, rows: list, width: int) -> None:
    for index, row in enumerate(rows):
        if len(row) != width:
            raise SystemExit("%s: row %d is %d wide, not %d" % (name, index, len(row), width))


def draw_pixels(rows: list, palette: dict, pixel: float) -> Image.Image:
    width, height = len(rows[0]), len(rows)
    image = Image.new("RGBA", (int(width * pixel), int(height * pixel)), (0, 0, 0, 0))
    paint = ImageDraw.Draw(image)
    for y, row in enumerate(rows):
        for x, letter in enumerate(row):
            if letter == ".":
                continue
            colour = palette.get(letter)
            if colour is None:
                raise SystemExit("no colour for '%s'" % letter)
            paint.rectangle([x * pixel, y * pixel, (x + 1) * pixel - 1, (y + 1) * pixel - 1], fill=colour)
    return image


def token(rows: list, palette: dict, radius: float, ring: str) -> Image.Image:
    """A crew token as the game draws it: a dark disc, the face at radius × 0.86, a ring. Drawn 4x then shrunk."""
    scale = 4
    size = int(radius * 2 + 8)
    image = Image.new("RGBA", (size * scale, size * scale), (0, 0, 0, 0))
    paint = ImageDraw.Draw(image)
    centre = size * scale / 2
    r = radius * scale
    paint.ellipse([centre - r, centre - r, centre + r, centre + r], fill="#1a2333")
    face_r = radius * 0.86 * scale
    pixel = face_r * 2 / len(rows[0])
    face = draw_pixels(rows, palette, pixel)
    image.alpha_composite(face, (int(centre - face.width / 2), int(centre - face.height / 2)))
    paint.ellipse([centre - r, centre - r, centre + r, centre + r], outline=ring, width=int(2.2 * scale))
    return image.resize((size, size), Image.LANCZOS)


def sheet(entries: list, title_height: int = 0) -> Image.Image:
    """Rows of: the portrait at 10x, then the 25 px and 32 px tokens at real size and at 4x."""
    rows = []
    for name, grid, palette in entries:
        big = draw_pixels(grid, palette, 10)
        small = token(grid, palette, 12.5, "#66ff66")
        card = token(grid, palette, 16, "#66ff66")
        rows.append((name, big, small, card))
    width = 170 + 170 + 40 + 40 + 4 * 33 + 4 * 40 + 60
    height = sum(max(r[1].height, 160) + 30 for r in rows) + 20
    out = Image.new("RGBA", (width, height), "#0d1220")
    paint = ImageDraw.Draw(out)
    y = 20
    for name, big, small, card in rows:
        paint.text((10, y), name, fill="#c8d4e6")
        out.alpha_composite(big, (10, y + 18))
        x = 200
        out.alpha_composite(small, (x, y + 30))
        out.alpha_composite(card, (x + 45, y + 26))
        out.alpha_composite(small.resize((small.width * 4, small.height * 4), Image.NEAREST), (x + 100, y + 18))
        out.alpha_composite(card.resize((card.width * 4, card.height * 4), Image.NEAREST), (x + 250, y + 10))
        y += max(big.height, 160) + 30
    return out


def main() -> None:
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    kitten_entries = []
    for number, (name, grid) in enumerate(KITTENS.items(), 1):
        check(name, grid, 13)
        kitten_entries.append(("K%d. HalfMech kitten: %s" % (number, name), grid, KITTEN_PALETTE))
    human_entries = []
    for number, (name, (grid, skin, hair)) in enumerate(HUMANS.items(), 1):
        check(name, grid, 15)
        palette = dict(HUMAN_COMMON)
        palette.update(SKINS[skin])
        palette.update(HAIRS[hair])
        human_entries.append(("M%d. Mercenary: %s" % (number, name), grid, palette))
    sheet(kitten_entries).save(out + "/halfmech-kittens.png")
    sheet(human_entries).save(out + "/mercenary-humans.png")


if __name__ == "__main__":
    main()
