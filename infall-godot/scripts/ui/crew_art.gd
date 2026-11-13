class_name CrewArt
extends RefCounted
## Crew drawn from sprite sheets, for the Art Style setting (GV 7F): `Art Style: Top Down > Facing > Tokens`.
## A setting for playtesting the art styles side by side; it can come out before a release.
##
## A race names its sheets in its race.xml, and content/crew-layouts.xml says where each animation's frames sit on a
## sheet. A race with no sheet in the chosen style is drawn as its token, as before, so the game plays the same in
## every style and each new sheet shows up by itself.

const LAYOUTS := "res://content/crew-layouts.xml"
const FACINGS := ["down", "right", "up", "left"]
const STAND_BACK := 6.0                  # pixels from the tile's middle a figure stands back from a console (GV 7G)

static var frame := 35.0                 # a frame's side, the size of a deck tile
static var _layouts: Dictionary = {}     # layout id -> {animation id -> {"ms": float, facing -> [row, column, frames]}}
static var _loaded := false
static var _recoloured: Dictionary = {}  # "sheet path subtype" -> an SVG sheet's picture in that subtype's colours
static var _outlines: Dictionary = {}    # a sheet's picture -> the same shapes in plain white, for a selection outline
static var _spans: Dictionary = {}       # a sheet's picture -> {facing -> where down its frame the standing figure starts and ends}


static func style() -> String:
	return Settings.get_value("art_style", "Top Down")


## The sheet a crew member is drawn from in the chosen style, in their subtype's colours: {"texture", "layout",
## "particles", "style", "stand_back"}, or {} for tokens.
static func sheet_for(race: RaceDef, subtype: String) -> Dictionary:
	var wanted := style()
	return {} if wanted == "Tokens" else _sheet(race, wanted, subtype)


## A token cut from the crew member's own sheet, for a race whose token is its sprite's face:
## {"texture", "centre", "radius"}, the circle to show in the sheet's pixels. {} for a race whose face is drawn.
static func token_for(race: RaceDef, subtype: String) -> Dictionary:
	if race.token.is_empty():
		return {}
	var sheet := _sheet(race, race.token.style, subtype)
	if sheet.is_empty():
		return {}
	var corner := Vector2(race.token.column - 1, race.token.row - 1) * frame
	return {"texture": sheet.texture, "centre": corner + race.token.centre, "radius": race.token.radius}


## A race's sheet in one style. A sheet for one GATOS species (GV 7A) is used only with that species; a sheet that
## names none suits the default, Terrans, and any race the species setting doesn't change.
static func _sheet(race: RaceDef, wanted: String, subtype: String) -> Dictionary:
	var species: String = Settings.get_value("gatos_species", "Terrans") if race.id == "terran" else ""
	for art in race.crew_art:
		var for_species: String = art.species if not String(art.species).is_empty() else ("Terrans" if race.id == "terran" else "")
		if art.style != wanted or for_species != species:
			continue
		var layout: Dictionary = _layout(art.layout)
		var texture := _texture(art.sheet, race, subtype)
		if texture == null or layout.is_empty():
			return {}
		return {"texture": texture, "layout": layout, "particles": art.particles, "style": art.style, "stand_back": art.stand_back}
	return {}


## A sheet's picture. A sheet kept as an SVG is drawn from its text, with its colour codes changed to the
## subtype's (GV 7F), once for each subtype worn.
static func _texture(path: String, race: RaceDef, subtype: String) -> Texture2D:
	if path.get_extension() != "svg":
		return Library.texture(path)
	var key := path + " " + subtype
	if not _recoloured.has(key):
		var text := FileAccess.get_file_as_string(path)
		var changes := CrewSkins.colour_changes(race, subtype)
		var codes := changes.keys()
		for index in codes.size():       # in two steps, so a code one part gives up can be another part's new one
			text = text.replace(codes[index], "{colour %d}" % index)
		for index in codes.size():
			text = text.replace("{colour %d}" % index, changes[codes[index]])
		var image := Image.new()
		if text.is_empty() or image.load_svg_from_string(text) != OK:
			_recoloured[key] = null
		else:
			image.fix_alpha_edges()      # so the see-through pixels beside the sprite don't show as a pale fringe
			_recoloured[key] = ImageTexture.create_from_image(image)
	return _recoloured[key]


## A sheet's figures as plain white shapes. Drawn a pixel to each side in a player's colour, under the figure, they
## make the thin outline that marks a selected crew member (GV 7G).
static func outline(sheet: Dictionary) -> Texture2D:
	var texture: Texture2D = sheet.texture
	if not _outlines.has(texture):
		var picture := texture.get_image()
		picture.convert(Image.FORMAT_RGBA8)
		var white := Image.create(picture.get_width(), picture.get_height(), false, Image.FORMAT_RGBA8)
		white.fill(Color.WHITE)
		var shapes := Image.create(picture.get_width(), picture.get_height(), false, Image.FORMAT_RGBA8)
		shapes.blit_rect_mask(white, picture, Rect2i(Vector2i.ZERO, picture.get_size()), Vector2i.ZERO)
		_outlines[texture] = ImageTexture.create_from_image(shapes)
	return _outlines[texture]


## How far down its frame the standing figure starts and ends when facing this way, in pixels (x its top, y its
## feet): where its head and the deck under it are, so a health bar can sit just clear of it whatever its height.
static func span(sheet: Dictionary, facing: String) -> Vector2:
	var texture: Texture2D = sheet.texture
	if not _spans.has(texture):
		_spans[texture] = {}
	var known: Dictionary = _spans[texture]
	if not known.has(facing):
		var standing := texture.get_image().get_region(Rect2i(region(sheet, "walk", facing, 0.0)))
		var drawn := standing.get_used_rect()
		known[facing] = Vector2(drawn.position.y, drawn.end.y) if drawn.has_area() else Vector2(0.0, frame)
	return known[facing]


static func has_animation(sheet: Dictionary, animation: String) -> bool:
	return sheet.layout.has(animation)


## Whether the sheet can show this animation with the crew member facing this way; an animation drawn one way only
## ("any") suits every facing. Without it the crew member is shown standing, and the game says what they are doing
## some other way.
static func has_pose(sheet: Dictionary, animation: String, facing: String) -> bool:
	var entry: Dictionary = sheet.layout.get(animation, {})
	return entry.has(facing) or entry.has("any")


## Where on the sheet the frame to show now sits. `seconds` is the animation's own clock; `progress` (0 to 1), when
## given, picks the frame by how far through the animation is, for one that plays once. A sheet without the
## animation, or without that facing of it, shows the crew member standing: the first frame of the walk.
static func region(sheet: Dictionary, animation: String, facing: String, seconds: float, progress: float = -1.0) -> Rect2:
	var layout: Dictionary = sheet.layout
	var entry: Dictionary = layout.get(animation, {})
	var cells: Array = entry.get(facing, entry.get("any", []))
	var index := 0
	if cells.is_empty():
		entry = layout.get("walk", {})
		cells = entry.get(facing, entry.get("down", [1, 1, 1]))
	elif progress >= 0.0:
		index = clampi(int(progress * cells[2]), 0, cells[2] - 1)
	else:
		index = int(seconds * 1000.0 / entry.ms) % int(cells[2])
	return Rect2((cells[1] - 1 + index) * frame, (cells[0] - 1) * frame, frame, frame)


## The particles the game makes while an animation plays (the sheets draw none): {"kind", "at"}, the point in the
## frame they start from for the way the crew member faces, or {} for none. Facing left, a sheet that gives no point
## of its own uses its right-facing one mirrored, as its left-facing frames are.
static func particles_at(sheet: Dictionary, animation: String, facing: String) -> Dictionary:
	var starts: Dictionary = sheet.particles.get(animation, {})
	var at: Variant = starts.get(facing, starts.get("any"))
	if at == null and facing == "left" and starts.has("right"):
		at = Vector2(frame - 1.0 - starts.right.x, starts.right.y)
	return {} if at == null else {"kind": starts.kind, "at": at}


static func _layout(id: String) -> Dictionary:
	if not _loaded:
		_loaded = true
		var root := XmlTree.load_file(LAYOUTS)
		if root:
			frame = root.get_float("frame", 35.0)
			for layout_node in root.all("layout"):
				var animations := {}
				for node in layout_node.all("animation"):
					var entry := {"ms": node.get_float("ms", 150.0)}
					for facing in FACINGS + ["any"]:
						if node.has_attr(facing):
							var cells: Array = []
							for value in node.get_attr(facing).split(","):
								cells.append(int(value))
							entry[facing] = cells
					animations[node.get_attr("id")] = entry
				_layouts[layout_node.get_attr("id")] = animations
	return _layouts.get(id, {})
