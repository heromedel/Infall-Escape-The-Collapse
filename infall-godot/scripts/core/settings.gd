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
	"low_mawjig_warning": [true, [true, false], "Low Mawjig Warning"],
	"shots_crossing_barrier": ["Shown", ["Shown", "Hidden"], "Shots Crossing Barrier"],
	"fullscreen": [false, [false, true], "Fullscreen"],
	"master_volume": [0.8, [], "Master Volume"],
	"music_volume": [0.6, [], "Music Volume"],
	"effects_volume": [0.8, [], "Effects Volume"],
}

var _values: Dictionary = {}


func _ready() -> void:
	for id in OPTIONS:
		_values[id] = OPTIONS[id][0]
	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		for id in OPTIONS:
			_values[id] = file.get_value("settings", id, _values[id])
	apply_display()


func get_value(id: String, fallback: Variant = null) -> Variant:
	return _values.get(id, fallback)


func set_value(id: String, value: Variant) -> void:
	_values[id] = value
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
