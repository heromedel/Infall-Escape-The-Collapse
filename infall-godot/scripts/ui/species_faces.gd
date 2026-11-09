class_name SpeciesFaces
extends RefCounted
## The crew faces the GATOS Species setting chooses (GV 7A, 7D): the mercenary humans (M1 to M5) for GATOS crew
## with Terrans, and the HalfMech kittens (K1 to K5) with Tabbys. The grids are docs/art/portraits/tools/portraits.py's,
## which heromedel liked as tokens. A crew member's face, skin, hair or eyes come from their name, so they stay the same.

## Which hair each human face takes: the grey veteran is grey or white; the rest any colour that reads on the token.
const HAIR_FOR := {"grey vet": ["grey", "white"]}
const YOUNG_HAIRS := ["black", "brown", "red", "blond"]
## The kittens' eyes: green, blue or purple (the grids draw them as G, B or V).
const EYE_COLOURS := ["#5fe08a", "#5aa8ff", "#c070ff"]

const KITTENS := {
	"visor": [
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
	"cyber eye": [
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
	"antenna ear": [
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
	"jaw plate": [
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
	"purple tuft": [
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
const KITTEN_PALETTE := {"#": "#07060b", "R": "#6e5e94", "Y": "#4d4662", "O": "#363045", "o": "#252030", "K": "#8a4e7e", "W": "#57506a", "N": "#b06a86", "M": "#5f6576", "m": "#3d414d", "P": "#aa28eb", "p": "#5a128c", "L": "#ebe1fa", "G": "#5fe08a", "B": "#5aa8ff", "V": "#c070ff", "H": "#ffffff", "e": "#07060b"}
const HUMANS := {
	"buzz cut veteran": [
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
	],
	"undercut with comm": [
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
	],
	"goggles up": [
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
	],
	"eyepatch": [
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
	],
	"grey vet": [
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
	],
}
const HUMAN_PALETTE := {"#": "#14101a", "E": "#14101a", "w": "#e8e2da", "C": "#3f4a3a", "c": "#2a3227", "Z": "#7a6a52", "T": "#c0c6cf", "R": "#c65a4a", "G": "#2fd0ff", "D": "#2a2a33"}
const SKINS := [{"S": "#f0c8a0", "s": "#d39f78", "m": "#b07a5c", "x": "#b8a08c"}, {"S": "#d49a6a", "s": "#b07a4e", "m": "#8a5a3a", "x": "#9a7a62"}, {"S": "#9c6644", "s": "#7a4c30", "m": "#5a3420", "x": "#6e5040"}, {"S": "#7c5036", "s": "#5e3a26", "m": "#43281a", "x": "#553a2c"}]
const HAIRS := {"black": {"H": "#3a3442", "h": "#221e29"}, "brown": {"H": "#6a4428", "h": "#4a2e1a"}, "red": {"H": "#b8542c", "h": "#86381c"}, "blond": {"H": "#d8b060", "h": "#a8823c"}, "grey": {"H": "#a8aab0", "h": "#7a7c84"}, "white": {"H": "#e6e6ea", "h": "#b4b4bc"}}


static func draw_human(canvas: CanvasItem, centre: Vector2, crew_name: String, r: float, alpha: float = 1.0) -> void:
	var h := absi(crew_name.hash())
	var face: String = HUMANS.keys()[h % HUMANS.size()]
	var hairs: Array = HAIR_FOR.get(face, YOUNG_HAIRS)
	var colours := HUMAN_PALETTE.duplicate()
	colours.merge(SKINS[(h / 7) % SKINS.size()], true)
	colours.merge(HAIRS[hairs[(h / 41) % hairs.size()]], true)
	var rows: Array = HUMANS[face]
	CrewFace.draw_rows(canvas, centre, _mirrored(rows, h), colours, r * 2.0 / rows[0].length(), alpha)


static func draw_kitten(canvas: CanvasItem, centre: Vector2, crew_name: String, r: float, alpha: float = 1.0) -> void:
	var h := absi(crew_name.hash())
	var rows: Array = KITTENS.values()[h % KITTENS.size()]
	var colours := KITTEN_PALETTE.duplicate()
	var eyes: String = EYE_COLOURS[(h / 7) % EYE_COLOURS.size()]
	for letter in ["G", "B", "V"]:
		colours[letter] = eyes
	CrewFace.draw_rows(canvas, centre, _mirrored(rows, h), colours, r * 2.0 / rows[0].length(), alpha)


## Half the crew face the other way, so a ship's crew don't look cloned.
static func _mirrored(rows: Array, h: int) -> Array:
	return rows.map(func(row: String): return row.reverse()) if (h / 53) % 2 == 1 else rows
