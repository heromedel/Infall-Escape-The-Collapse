extends Node
## Clicks through the ship view with simulated mouse and keys, the way a player would, and prints whether each
## step did what it should. Run with a display: xvfb-run godot --path . tools/input_test.tscn

var main: Node


func _ready() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RunState.SAVE_PATH))
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(0.5)
	main.start_new_run("outrider")
	await _wait(0.8)
	await _press_first_event_button()
	await _wait(0.5)
	var battle: BattleScreen = main.battle
	var ship: Ship = battle.selected_ship
	var member: CrewMember = ship.crew[1]
	# 1. Click a crew token
	print("token at ", _screen_of(ship, member.position), " final ", get_viewport().get_final_transform(), " hovered ", get_viewport().gui_get_hovered_control(), " overlays ", main.overlays.get_children(), " hold ", battle.hold_pause)
	await _click(_screen_of(ship, member.position), MOUSE_BUTTON_LEFT)
	print("after click hover crew ", battle.hover_crew, " hover ship ", battle.hover_ship, " room ", battle.hover_room, " mouse ", battle.world.get_global_mouse_position(), " member world ", main.encounter.local_to_world(ship, member.position), " hovered control ", get_viewport().gui_get_hovered_control())
	_check("click selects a crew member", battle.selected_crew.has(member))
	# 2. Right click the engine room to send them there
	var engines := ship.system_by("engines")
	var tile: Vector2i = ship.rooms[engines.room].cells.back()
	await _click(_screen_of(ship, ship.design.cell_centre(tile)), MOUSE_BUTTON_RIGHT)
	_check("right click orders them to that tile", member.destination == tile)
	await _wait(6.0)
	_check("they walk to that tile", member.cell == tile)
	# 3. Space pauses
	await _key(KEY_SPACE)
	_check("space pauses", battle.paused)
	await _key(KEY_SPACE)
	_check("space unpauses", not battle.paused)
	# 4. A fight: arm a weapon from the HUD and aim it at an enemy room
	main.start_fight("terran-pirates")
	battle.paused = false
	await _wait(0.8)
	var slot: WeaponSlot = ship.weapons[0]
	var region := _hud_region(slot.def.display_name())
	_check("the weapon slot is on the HUD", not region.is_empty())
	if not region.is_empty():
		await _click(region.rect.get_center(), MOUSE_BUTTON_LEFT)
		_check("clicking the slot arms it", battle.aim_mode == "weapon" and battle.aim_slot == slot)
		var enemy: Ship = main.encounter.living(1)[0]
		var target_room: int = enemy.system_by("shields").room
		var target_tile: Vector2i = enemy.rooms[target_room].cells.back()
		await _click(_screen_of(enemy, enemy.design.cell_centre(target_tile)), MOUSE_BUTTON_LEFT)
		_check("clicking an enemy tile aims at that tile", slot.target_ship == enemy and slot.target_room == target_room and slot.target_cell == target_tile)
	# 5. Right click a system's power bars to switch it off, click to switch it on again
	var medbay := ship.system_by("medbay")
	var life := ship.system_by("oxygen")
	var life_region := _hud_region(life.display_name() + " (level")
	if not life_region.is_empty():
		await _click(life_region.rect.get_center(), MOUSE_BUTTON_RIGHT)
		_check("right click switches Life Support off", not life.enabled)
		var medbay_region := _hud_region(medbay.display_name() + " (level")
		await _click(medbay_region.rect.get_center(), MOUSE_BUTTON_LEFT)
		_check("click switches the Medbay on", medbay.enabled)
	# 6. A door click
	var door: ShipDoor = ship.doors[0]
	var door_point: Vector2 = ship.design.cell_centre(door.cell_a) + Vector2(door.direction) * ShipDesign.TILE * 0.5
	battle.paused = true
	await _click(_screen_of(ship, door_point), MOUSE_BUTTON_LEFT)
	_check("clicking a door opens it", door.held_open)
	await _wait(0.3)
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/input_test.png")
	get_tree().quit()


func _screen_of(ship: Ship, local: Vector2) -> Vector2:
	var world_point: Vector2 = main.encounter.local_to_world(ship, local)
	return get_viewport().get_canvas_transform() * world_point if false else main.battle.world.get_global_transform_with_canvas() * world_point


func _hud_region(text_start: String) -> Dictionary:
	for region in main.battle.hud._regions:
		if String(region.tooltip).begins_with(text_start):
			return region
	return {}


func _click(viewport_point: Vector2, button: int) -> void:
	# Events arrive in window pixels; the game draws at 1920x1080 and stretches to the window
	var at: Vector2 = get_viewport().get_final_transform() * viewport_point
	Input.warp_mouse(at)
	await _wait(0.05)
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	Input.parse_input_event(motion)
	await _wait(0.05)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.global_position = at
		event.button_index = button
		event.pressed = pressed
		Input.parse_input_event(event)
		await _wait(0.05)


func _key(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await _wait(0.05)


func _press_first_event_button() -> void:
	for child in main.overlays.get_children():
		if child is EventWindow:
			for node in child.body.get_children():
				if node is Button:
					node.emit_signal("pressed")
					await _wait(0.4)
					await _press_first_event_button()
					return


func _check(what: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
