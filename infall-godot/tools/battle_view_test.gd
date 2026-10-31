extends Node
## Shows a fight and saves screenshots. Environment: E (enemy ship ids, comma separated), SHOTS (seconds,
## comma separated), OUT (folder), P (player ship ids). Run with a display: xvfb-run godot --path . tools/battle_view_test.tscn

var screen: BattleScreen
var shots: Array = []
var elapsed := 0.0
var out := ""


func _ready() -> void:
	out = OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/claude-0/shots"
	DirAccess.make_dir_recursive_absolute(out)
	for value in (OS.get_environment("SHOTS") if OS.get_environment("SHOTS") != "" else "1,6,14").split(","):
		shots.append(float(value))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var run := RunState.new()
	var players: Array = []
	for id in (OS.get_environment("P") if OS.get_environment("P") != "" else "outrider").split(","):
		players.append(Ship.from_design(Library.ship(id), 0, rng))
	var enemies: Array = []
	for id in (OS.get_environment("E") if OS.get_environment("E") != "" else "pirate-hijacker.cutpurse").split(","):
		if id != "none":
			enemies.append(Ship.from_design(Library.ship(id), 1, rng))
	var encounter := Encounter.new()
	encounter.wallet = run
	encounter.hazard = OS.get_environment("HAZARD")
	encounter.setup(players, enemies, 3)
	screen = BattleScreen.new()
	add_child(screen)
	screen.show_encounter(encounter, run, 12345, 0.3, true)
	if not enemies.is_empty():
		for ship in players:
			for slot in ship.weapons:
				slot.target_ship = enemies[0]
				slot.target_room = 0
				slot.autofire = true
	if OS.get_environment("SELECT") != "":
		screen.select_crew_member(players[0].crew[0], false)


func _process(delta: float) -> void:
	elapsed += delta
	if not shots.is_empty() and elapsed >= shots[0]:
		var at: float = shots.pop_front()
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		image.save_png("%s/shot_%05.1f.png" % [out, at])
		if shots.is_empty():
			get_tree().quit()
