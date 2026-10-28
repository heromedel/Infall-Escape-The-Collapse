## Player settings. Each setting lists its choices with the default first, and is saved between sessions.
extends Node

const SAVE_PATH := "user://settings.cfg"

## key: { label, choices (default first), help }
const OPTIONS := {
	"draw_per_turn": {"label": "Cards Drawn Per Turn", "choices": ["1", "2"],
		"help": "How many cards each captain draws at the start of a turn. 2 makes battles faster."},
	"opening_power": {"label": "Opening Hand Power", "choices": ["Random", "2 Guaranteed"],
		"help": "Random: draw a normal opening hand and use Reroute Power if you need power. 2 Guaranteed puts at least 2 Power cards in each opening hand."},
	"sensor_fog": {"label": "Sensor Fog", "choices": ["On", "Off"],
		"help": "On: you only see what your Sensors show. Off: you see the enemy's crew, power and hand."},
	"hull_scale": {"label": "Hull Scale", "choices": ["Ship Value", "75%", "50%", "150%"],
		"help": "Multiplies every ship's hull. Lower makes battles shorter."},
	"engine_burn": {"label": "Engine Burn", "choices": ["On", "Off"],
		"help": "On: spend power on Engines for +5% evasion each until your next turn."},
	"jump_escape": {"label": "Jump Escape", "choices": ["On", "Off"],
		"help": "On: Spool Jump Drive cards build charges; at 3 you escape and the battle ends."},
	"crew_fights": {"label": "Crew Fights", "choices": ["On", "Off"],
		"help": "On: boarders and defenders in the same system trade wounds at the end of the turn."},
	"ai_level": {"label": "Enemy Captain", "choices": ["Normal", "Easy", "Hard"],
		"help": "How well the enemy plays."},
	"first_turn": {"label": "First Turn", "choices": ["Coin Flip", "You", "Enemy"],
		"help": "Who takes the first turn. The captain going first skips their first draw."},
	"animation_speed": {"label": "Animation Speed", "choices": ["Normal", "Fast", "Slow"],
		"help": "How fast cards and shots move."},
	"sound": {"label": "Sound", "choices": ["On", "Off"], "help": "Sound effects."},
	"budget": {"label": "Designer Budget", "choices": ["Off", "60 Points", "80 Points"],
		"help": "A design point limit in the Ship Designer."},
}

var values := {}


func _ready() -> void:
	for key in OPTIONS:
		values[key] = OPTIONS[key].choices[0]
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		for key in OPTIONS:
			var saved = config.get_value("settings", key, values[key])
			if saved in OPTIONS[key].choices:
				values[key] = saved


func value(key: String) -> String:
	return values.get(key, OPTIONS[key].choices[0])


func set_value(key: String, choice: String) -> void:
	values[key] = choice
	var config := ConfigFile.new()
	for saved_key in values:
		config.set_value("settings", saved_key, values[saved_key])
	config.save(SAVE_PATH)


## Steps a setting to its next choice, wrapping around.
func cycle(key: String) -> void:
	var choices: Array = OPTIONS[key].choices
	set_value(key, choices[(choices.find(value(key)) + 1) % choices.size()])


## Multiplier for animation durations.
func animation_scale() -> float:
	match value("animation_speed"):
		"Fast": return 0.55
		"Slow": return 1.6
	return 1.0


func hull_multiplier() -> float:
	match value("hull_scale"):
		"75%": return 0.75
		"50%": return 0.5
		"150%": return 1.5
	return 1.0


func budget_limit() -> int:
	match value("budget"):
		"60 Points": return 60
		"80 Points": return 80
	return 0
