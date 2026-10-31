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
## The approved face comes up most often.
const FACE_CHOICES := ["level", "level", "level", "stern", "alert", "wink"]
const FURS := [
	{"Y": "#f0a850", "O": "#d9822b", "o": "#a85a1e"},  # ginger, as the concept
	{"Y": "#c4c8d2", "O": "#949aa8", "o": "#646a78"},  # grey
	{"Y": "#7a7a88", "O": "#52525e", "o": "#36363f"},  # charcoal
	{"Y": "#f6e6c8", "O": "#e2c9a0", "o": "#b89a70"},  # cream
	{"Y": "#c89c6c", "O": "#946c44", "o": "#634528"},  # brown tabby
]
const FIXED := {"#": "#1a1220", "K": "#e89aa8", "W": "#f3dcb8", "H": "#ffffff", "N": "#e07a8a", "S": "#f6c7a0"}


## The variant a name always gets: { fur, face, mirrored, scar }.
static func variant_for(crew_name: String) -> Dictionary:
	var h := absi(crew_name.hash())
	return {
		"fur": FURS[h % FURS.size()],
		"face": FACE_CHOICES[(h / 7) % FACE_CHOICES.size()],
		"mirrored": (h / 53) % 2 == 1,
		"scar": (h / 107) % 3 == 0,
	}


## The head's pixels for a variant as rows of palette letters.
static func rows_for(variant: Dictionary) -> Array:
	var rows: Array = []
	for row in HEAD:
		rows.append(row if variant.scar else row.replace("S", "O"))
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
	var rows := rows_for(variant)
	var origin := center - Vector2(WIDTH, HEIGHT) * pixel / 2.0
	for y in HEIGHT:
		var row: String = rows[y]
		for x in WIDTH:
			var letter := row[x]
			if letter == ".":
				continue
			var hex: String = variant.fur.get(letter, FIXED.get(letter, "#ff00ff"))
			canvas.draw_rect(Rect2(origin + Vector2(x, y) * pixel, Vector2(pixel, pixel)), Color(Color(hex), alpha))


static func _put(row: String, column: int, cells: String) -> String:
	return row.left(column) + cells + row.substr(column + cells.length())
