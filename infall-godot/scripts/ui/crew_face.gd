## Crew token faces: the GATOS cat concept's head (Cloud-C-Art, docs/art/terran/cat-concept-for-gatos, face C:
## level lids, no mouth line), front facing, in pixel art. Each crew member gets a fixed variant from their name:
## fur colour, eyes, which side the notched ear is on, and whether they have the cheek scar.
## The variants other than the approved face are Ai-Generated-Proposal. Shared with the card game version.
class_name CrewFace
extends RefCounted

## The head from the concept sprite, 13 × 11 pixels, closed with an outline under the chin. Y O o: fur lit, base
## and shade; K inside the ears; W muzzle; N nose; S scar; # outline. The eyes are drawn over it (see EYES).
const HEAD := [
	"..#......##..",
	".#Y#....#oO#.",
	"#YKO#####OKO#",
	"#YOOoOoOoOOo#",
	"#YOOOOOOOOOo#",
	"#YOOOOOOOOOo#",
	"#YSOWWWWWOOo#",
	"#YSOWWNWWOOo#",
	"#YOOWWWWWOOo#",
	".#oOOWWWOOo#.",
	"..#########..",
]
const WIDTH := 13
const HEIGHT := 11
## Eyes sit at columns 3–4 and 8–9, rows 5–6. Each face: the left eye's two rows, then the right eye's.
## H is the glint, # dark, O closed fur. "brow" adds a dark pixel above each eye's inner corner.
const EYES := {
	"level": {"left": ["##", "H#"], "right": ["##", "H#"]},          # the approved face C: level, half-lowered lids
	"stern": {"left": ["##", "H#"], "right": ["##", "H#"], "brow": true},
	"alert": {"left": ["H#", "##"], "right": ["H#", "##"]},
	"wink": {"left": ["OO", "##"], "right": ["##", "H#"]},
}
## The approved face comes up most often, the others often enough to tell a crew apart (heromedel, 2026-11-01).
const FACE_CHOICES := ["level", "level", "stern", "alert", "wink"]
## Coat patterns (heromedel, 2026-11-01; the patterns themselves Ai-Generated-Proposal): pixels laid over the head,
## as [row, column, letter]. P and Q are patch colours, T an ear tuft.
const PATTERNS := {
	"plain": [],
	"tabby": [[4, 5, "o"], [4, 7, "o"], [6, 10, "o"], [8, 2, "o"], [8, 10, "o"], [9, 3, "o"]],
	"tuxedo": [[4, 6, "W"], [5, 6, "W"], [9, 4, "W"], [9, 7, "W"]],
	"calico": [[1, 2, "P"], [2, 3, "P"], [3, 2, "P"], [3, 3, "P"], [4, 2, "P"], [3, 9, "Q"], [3, 10, "Q"], [4, 9, "Q"], [4, 10, "Q"], [5, 10, "Q"], [8, 9, "Q"]],
}
const PATTERN_CHOICES := ["plain", "plain", "tabby", "tabby", "tuxedo", "calico"]
const TUXEDO_FUR := {"Y": "#565664", "O": "#33333d", "o": "#22222a"}
const CALICO_FUR := {"Y": "#faf0dc", "O": "#ecdcc0", "o": "#c8b494", "P": "#e0893a", "Q": "#3e3e48"}
const FURS := [
	{"Y": "#f0a850", "O": "#d9822b", "o": "#a85a1e"},  # ginger, as the concept
	{"Y": "#c4c8d2", "O": "#949aa8", "o": "#646a78"},  # grey
	{"Y": "#7a7a88", "O": "#52525e", "o": "#36363f"},  # charcoal
	{"Y": "#f6e6c8", "O": "#e2c9a0", "o": "#b89a70"},  # cream
	{"Y": "#c89c6c", "O": "#946c44", "o": "#634528"},  # brown tabby
]
const FIXED := {"#": "#1a1220", "K": "#e89aa8", "W": "#f3dcb8", "H": "#ffffff", "N": "#e07a8a", "S": "#f6c7a0"}


## The variant a name always gets: { fur, face, pattern, tufts, mirrored, scar }.
static func variant_for(crew_name: String) -> Dictionary:
	var h := absi(crew_name.hash())
	var pattern: String = PATTERN_CHOICES[(h / 211) % PATTERN_CHOICES.size()]
	var fur: Dictionary = FURS[h % FURS.size()]
	if pattern == "tuxedo":
		fur = TUXEDO_FUR
	elif pattern == "calico":
		fur = CALICO_FUR
	fur = fur.duplicate()
	fur["T"] = "#" + Color(fur.Y).lightened(0.4).to_html(false)
	return {
		"fur": fur,
		"face": FACE_CHOICES[(h / 7) % FACE_CHOICES.size()],
		"pattern": pattern,
		"tufts": (h / 389) % 4 == 0,
		"mirrored": (h / 53) % 2 == 1,
		"scar": (h / 107) % 3 == 0,
	}


## The head's pixels for a variant as rows of palette letters.
static func rows_for(variant: Dictionary) -> Array:
	var rows: Array = []
	for row in HEAD:
		rows.append(row if variant.scar else row.replace("S", "O"))
	for pixel in PATTERNS.get(variant.get("pattern", "plain"), []):
		rows[pixel[0]] = _put(rows[pixel[0]], pixel[1], pixel[2])
	if variant.get("tufts", false):
		rows[0] = _put(_put(rows[0], 2, "T"), 9, "T")
	var eyes: Dictionary = EYES[variant.face]
	for i in 2:
		rows[5 + i] = _put(rows[5 + i], 3, eyes.left[i])
		rows[5 + i] = _put(rows[5 + i], 8, eyes.right[i])
	if eyes.get("brow", false):
		rows[4] = _put(_put(rows[4], 4, "#"), 8, "#")
	if variant.mirrored:
		rows = rows.map(func(row: String): return row.reverse())
	return rows


## Draws the face centred on a point, each pixel `pixel` units wide.
static func draw(canvas: CanvasItem, center: Vector2, crew_name: String, pixel: float, alpha: float = 1.0) -> void:
	var variant := variant_for(crew_name)
	var colours := FIXED.duplicate()
	colours.merge(variant.fur, true)
	draw_rows(canvas, center, rows_for(variant), colours, pixel, alpha)


## Draws any pixel grid (rows of palette letters, "." clear) centred on a point.
static func draw_rows(canvas: CanvasItem, center: Vector2, rows: Array, colours: Dictionary, pixel: float, alpha: float = 1.0) -> void:
	var size := Vector2(String(rows[0]).length(), rows.size())
	var origin := center - size * pixel / 2.0
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var letter := row[x]
			if letter == ".":
				continue
			var colour := Color(colours.get(letter, "#ff00ff"))
			canvas.draw_rect(Rect2(origin + Vector2(x, y) * pixel, Vector2(pixel, pixel)), Color(colour, colour.a * alpha))


static func _put(row: String, column: int, cells: String) -> String:
	return row.left(column) + cells + row.substr(column + cells.length())
