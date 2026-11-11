extends Node
## Settings (autoload): every option, with its default first as the GDD writes them (GDD 1K), saved to
## user://settings.cfg. Screens read options with get_value and change them with set_value.

const PATH := "user://settings.cfg"

## id -> [default, the choices in order (default first), what the settings screen calls it]
const OPTIONS := {
	"auto_pause": [false, [false, true], "Auto Pause"],
	"auto_pause_seconds": [5.0, [5.0, 3.0, 8.0, 12.0], "Auto Pause Interval (seconds)"],
	"event_auto_pause": [true, [true, false], "Events Pause the Game"],
	"terran_conduits": [true, [true, false], "Terran Ship Conduits"],
	"player_power_colour": ["Default (Green)", ["Default (Green)", "Racial", "Specific Color"], "Player Power Color"],
	"run_length": ["Standard", ["Standard", "Short"], "Run Length"],
	"difficulty": ["Normal", ["Normal", "Easy", "Hard"], "Difficulty"],
	"map_zoom": ["Clamped", ["Clamped", "Free"], "Map Zoom"],
	"formation": ["Curve", ["Curve", "Inverted Curve", "Flat Row"], "Squad Formation"],
	"screen_shake": [true, [true, false], "Screen Shake"],
	"hud_layout": ["Movable", ["Movable", "Locked"], "HUD Layout"],
	"hud_card_opacity": ["85%", ["85%", "100%", "70%"], "HUD Card Opacity"],
	"collapsed_cards_reopen": [true, [true, false], "Collapsed Cards Reopen on Change"],
	"reopened_cards_fold_back": [true, [true, false], "Reopened Cards Fold Back"],
	"low_mawjig_warning": [true, [true, false], "Low Mawjig Warning"],
	"gatos_species": ["Terrans", ["Terrans", "Tabbys"], "GATOS Species"],
	"mouse_control": ["Left Selects, Right Orders", ["Left Selects, Right Orders", "Left Selects and Orders, Right Deselects"], "Mouse Control"],
	"local_coop_view": ["Split", ["Split", "Shared"], "Local Co-op View"],
	"battlefield": ["Vertical", ["Vertical", "Horizontal"], "Battlefield"],
	"art_style": ["Top Down", ["Top Down", "Facing", "Tokens"], "Art Style"],
	"fullscreen": [false, [false, true], "Fullscreen"],
	"master_volume": [0.8, [], "Master Volume"],
	"music_volume": [0.6, [], "Music Volume"],
	"effects_volume": [0.8, [], "Effects Volume"],
}

## The settings window's tabs (GV 14G), in order, and the settings on each.
const TABS := {
	"Game": ["run_length", "difficulty", "terran_conduits", "gatos_species", "low_mawjig_warning"],
	"Battle": ["battlefield", "formation", "auto_pause", "auto_pause_seconds", "event_auto_pause", "screen_shake", "player_power_colour"],
	"Controls": ["mouse_control", "map_zoom"],
	"HUD": ["hud_layout", "hud_card_opacity", "collapsed_cards_reopen", "reopened_cards_fold_back"],
	"Players": ["local_coop_view"],
	"Display and Sound": ["art_style", "fullscreen", "master_volume", "music_volume", "effects_volume"],
}

## Settings that change what happens in a run, not just how it looks: in a session every machine uses the host's
## (GV 4C), so the simulation runs the same everywhere.
const RULES := ["terran_conduits", "run_length", "difficulty", "formation", "gatos_species", "auto_pause",
		"auto_pause_seconds", "event_auto_pause"]

var _values: Dictionary = {}
var session_rules: Dictionary = {}   # the host's values of RULES while a run is shared
var rule_changed: Callable           # set by the session: sends a rule change to every machine


func _ready() -> void:
	for id in OPTIONS:
		_values[id] = OPTIONS[id][0]
	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		for id in OPTIONS:
			_values[id] = file.get_value("settings", id, _values[id])
	apply_display()


func get_value(id: String, fallback: Variant = null) -> Variant:
	if session_rules.has(id):
		return session_rules[id]
	return _values.get(id, fallback)


## This machine's values of the rules, for a session's start.
func rules_snapshot() -> Dictionary:
	var rules := {}
	for id in RULES:
		rules[id] = _values.get(id, OPTIONS[id][0])
	return rules


func set_value(id: String, value: Variant) -> void:
	_values[id] = value
	if session_rules.has(id) and rule_changed.is_valid():
		rule_changed.call(id, value)   # the host's change reaches every machine as an order
	var file := ConfigFile.new()
	for key in _values:
		file.set_value("settings", key, _values[key])
	file.save(PATH)
	if id == "fullscreen":
		apply_display()


func apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if _values.get("fullscreen", false) else DisplayServer.WINDOW_MODE_WINDOWED)
