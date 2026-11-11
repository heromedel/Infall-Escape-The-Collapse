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

static var frame := 35.0                 # a frame's side, the size of a deck tile
static var _layouts: Dictionary = {}     # layout id -> {animation id -> {"ms": float, facing -> [row, column, frames]}}
static var _loaded := false


static func style() -> String:
	return Settings.get_value("art_style", "Top Down")


## The sheet a race's crew are drawn from in the chosen style: {"texture", "layout"}, or {} for tokens.
## A sheet for one GATOS species (GV 7A) is used only with that species; a sheet that names none suits the
## default, Terrans, and any race the species setting doesn't change.
static func sheet_for(race: RaceDef) -> Dictionary:
	var wanted := style()
	if wanted == "Tokens":
		return {}
	var species: String = Settings.get_value("gatos_species", "Terrans") if race.id == "terran" else ""
	for art in race.crew_art:
		var for_species: String = art.species if not String(art.species).is_empty() else ("Terrans" if race.id == "terran" else "")
		if art.style != wanted or for_species != species:
			continue
		var layout: Dictionary = _layout(art.layout)
		var texture := Library.texture(art.sheet)
		if texture == null or layout.is_empty():
			return {}
		return {"texture": texture, "layout": layout}
	return {}


static func has_animation(sheet: Dictionary, animation: String) -> bool:
	return sheet.layout.has(animation)


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
