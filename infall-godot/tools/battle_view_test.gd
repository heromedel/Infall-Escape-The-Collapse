extends Node
## Shows a fight and saves screenshots. Environment: E (enemy ship ids, comma separated), SHOTS (seconds,
## comma separated), OUT (folder), P (player ship ids). Run with a display: xvfb-run godot --path . tools/battle_view_test.tscn

var screen: BattleScreen
var shots: Array = []
var elapsed := 0.0
var out := ""
var zoom_ship: Ship = null


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
	screen.show_encounter(encounter, run, int(OS.get_environment("LOOK")) if OS.get_environment("LOOK") != "" else 12345, 0.3, true)
	if not enemies.is_empty():
		for ship in players:
			for slot in ship.weapons:
				slot.aim_at(enemies[0], enemies[0].rooms[0].cells[0])
				slot.autofire = true
	if OS.get_environment("STAGE") != "":
		# fires in two rooms, a scorched tile, and a hurt crew member sent to the medbay
		var ship: Ship = players[0]
		if OS.get_environment("STAGE") != "heal":
			for room in ship.rooms.slice(1, 3):
				room.fires[room.cells[0]] = 60.0
		ship.rooms[3].scorch[ship.rooms[3].cells[0]] = true
		var medbay := ship.system_by("medbay")
		if medbay:
			ship.crew[0].health = 30.0
			medbay.enabled = true
			medbay.power = maxi(1, medbay.power)
			var sensors := ship.system_by("sensors")
			if sensors:
				sensors.enabled = false
			CrewBrain.order_to_room(ship.crew[0], medbay.room, true)
	if OS.get_environment("ZOOM") != "":
		zoom_ship = players[0]
	if OS.get_environment("SELECT") != "":
		screen.select_crew_member(players[0].crew[0], false)


func _process(delta: float) -> void:
	elapsed += delta
	if zoom_ship:
		screen.camera.user_moved = true
		screen.camera.target_zoom = float(OS.get_environment("ZOOM"))
		screen.camera.target_position = screen.encounter.local_to_world(zoom_ship, zoom_ship.design.cell_centre(zoom_ship.rooms[2].cells[0]))
		screen.camera.position = screen.camera.target_position
		screen.camera.zoom = Vector2.ONE * screen.camera.target_zoom
	if not shots.is_empty() and elapsed >= shots[0]:
		var at: float = shots.pop_front()
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		image.save_png("%s/shot_%05.1f.png" % [out, at])
		if shots.is_empty():
			get_tree().quit()
