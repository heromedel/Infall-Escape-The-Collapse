## Writes a battle to a log file for reviewing real play. Every entry is two lines: a machine line with every
## field (tab-separated time, turn and JSON), then a human-readable line written from it.
## Files go to user://logs/ (on Windows: %APPDATA%\Godot\app_userdata\Infall- Deck Collapse\logs).
class_name BattleLogFile
extends RefCounted

const FOLDER := "user://logs"
const KEEP_NEWEST := 50

var path := ""
var _file: FileAccess
var _started_ms := 0


static func folder_path() -> String:
	return ProjectSettings.globalize_path(FOLDER)


func open(battle: Battle) -> void:
	DirAccess.make_dir_recursive_absolute(FOLDER)
	_delete_old_logs()
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	path = "%s/battle_%s.log" % [FOLDER, stamp]
	_file = FileAccess.open(path, FileAccess.WRITE)
	_started_ms = Time.get_ticks_msec()
	var settings := {}
	for key in Settings.OPTIONS:
		settings[key] = Settings.value(key)
	write({"type": "battle_start", "player": battle.ships[0].name, "enemy": battle.ships[1].name,
		"seed": battle.rng.seed, "first": battle.active_side, "settings": settings},
		"Battle started: %s (you) against %s." % [battle.ships[0].name, battle.ships[1].name], battle.turn_number)
	for side in 2:
		write({"type": "ship_xml", "side": side, "xml": battle.ships[side].design.to_xml()},
			"%s design recorded." % battle.ships[side].name, battle.turn_number)


## Writes one battle event as its two lines.
func write_event(event: Dictionary, battle: Battle) -> void:
	write(_machine_fields(event), describe(event, battle), battle.turn_number)


func write(fields: Dictionary, human: String, turn: int) -> void:
	if _file == null:
		return
	var seconds := (Time.get_ticks_msec() - _started_ms) / 1000.0
	_file.store_line("M\t%.2f\tturn=%d\t%s" % [seconds, turn, JSON.stringify(fields)])
	_file.store_line("H\t%.2f\tturn=%d\t%s" % [seconds, turn, human])
	_file.flush()


func close() -> void:
	if _file:
		_file.close()
		_file = null


## A readable sentence for any event; log events already carry their own sentence.
static func describe(event: Dictionary, battle: Battle) -> String:
	var side_name := ""
	if event.has("side") and int(event.side) in [0, 1]:
		side_name = battle.ships[int(event.side)].name
	match event.type:
		"log":
			return event.text
		"card_played":
			return "%s plays %s." % [side_name, event.definition.name]
		"shot":
			return "%s shot %d at %s: %s%s." % [side_name, event.index + 1, event.target, event.result,
				"" if event.damage == 0 else " for %d" % event.damage]
		"damage":
			return "%s's %s takes %d system damage, %d hull (%s)." % [side_name, event.system, event.system_damage, event.hull, event.cause]
		"drew":
			return "%s draws a card." % side_name
		"turn_start":
			return "Turn %d starts for %s." % [event.turn, side_name]
		"battle_over":
			return "Battle over: %s." % event.outcome
	var parts: Array[String] = []
	for key in event:
		if key != "type":
			parts.append("%s=%s" % [key, event[key]])
	return "%s%s %s" % [side_name + ": " if side_name != "" else "", event.type, ", ".join(parts)]


## Every field of the event, with card definitions reduced to their names so lines stay short.
static func _machine_fields(event: Dictionary) -> Dictionary:
	var fields := event.duplicate(true)
	if fields.has("definition"):
		fields.definition = fields.definition.get("name", "")
	return fields


func _delete_old_logs() -> void:
	var names := Array(DirAccess.get_files_at(FOLDER)).filter(func(n): return n.ends_with(".log"))
	names.sort()
	while names.size() >= KEEP_NEWEST:
		DirAccess.remove_absolute("%s/%s" % [FOLDER, names.pop_front()])
