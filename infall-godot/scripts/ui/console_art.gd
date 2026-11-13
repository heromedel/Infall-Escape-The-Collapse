class_name ConsoleArt
extends RefCounted
## System consoles drawn from art (GV 7G). A console sits against its wall with the system's symbol on its screen
## or bulb, and the crew member who works it stands on the same tile in front of it.
##
## Each style is a folder in content/consoles with a console.xml and its art. A race names its style in its
## race.xml (consoles="tower"); a race that names none gets the style marked default. The art carries no symbol:
## the game draws it, so its colour can show whether the system is powered, damaged or broken.

const FOLDER := "res://content/consoles"
const DETAIL := 4.0      # an SVG is drawn at this many times its size, so it stays sharp when the view zooms in

static var _styles: Dictionary = {}     # style id -> {"fit", "scale", "box", "gap", "glow", "consoles": {system id or "": {...}}}
static var _default := ""
static var _loaded := false


## The console a race's ships have for a system: {"texture", "symbol", "symbol_size", "fit", "scale", "box", "gap",
## "glow"}, or {} when there is no art for it. `symbol` is the point in the art's 35-pixel frame where the symbol
## goes. fit "turned": drawn for the north wall and turned to face its own. fit "upright": never turned, drawn at
## `scale` with the edge of its `box` (left, top, right, bottom) `gap` pixels from its wall.
static func console_for(race: RaceDef, system_id: String) -> Dictionary:
	_load()
	var style: Dictionary = _styles.get(race.consoles if race else "", _styles.get(_default, {}))
	if style.is_empty():
		return {}
	var consoles: Dictionary = style.consoles
	var console: Dictionary = consoles.get(system_id, consoles.get("", {}))
	if console.is_empty():
		return {}
	if not console.has("texture"):
		console.texture = _texture(console.path)
	if console.texture == null:
		return {}
	var found := console.duplicate()
	found.merge(style)
	return found


static func _texture(path: String) -> Texture2D:
	if path.get_extension() != "svg":
		return Library.texture(path)
	var image := Image.new()
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty() or image.load_svg_from_string(text, DETAIL) != OK:
		return null
	image.fix_alpha_edges()
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var dir := DirAccess.open(FOLDER)
	if dir == null:
		return
	for folder in dir.get_directories():
		var root := XmlTree.load_file(FOLDER + "/" + folder + "/console.xml")
		if root == null:
			continue
		var box := root.get_attr("box", "0,0,35,35").split_floats(",")
		var consoles := {}
		for node in root.all("console"):
			var symbol := node.get_attr("symbol", "17.5,17.5").split_floats(",")
			consoles[node.get_attr("system")] = {"path": FOLDER + "/" + folder + "/" + node.get_attr("art"),
					"symbol": Vector2(symbol[0], symbol[1]), "symbol_size": node.get_float("symbol_size", 15.0)}
		var id := root.get_attr("id", folder)
		_styles[id] = {"fit": root.get_attr("fit", "turned"), "scale": root.get_float("scale", 1.0), "box": box,
				"gap": root.get_float("gap", 0.0), "glow": root.get_float("glow", 0.0), "consoles": consoles}
		if root.get_bool("default", false):
			_default = id
