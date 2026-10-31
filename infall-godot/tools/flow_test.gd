extends Node
## Drives the real game flow without a player and saves screenshots along the way: the title, the first event,
## the map, a store, a fight. Run with a display: xvfb-run godot --path . tools/flow_test.tscn

var main: Node
var out := "/tmp/claude-0/flow"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RunState.SAVE_PATH))
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(1.0)
	await _shot("01_title")
	main.start_new_run("outrider")
	await _wait(1.2)
	await _shot("02_first_event")
	await _click_first_choice()
	await _wait(1.0)
	await _shot("03_after_event")
	main.open_map()
	await _wait(0.8)
	await _shot("04_map")
	_close_overlays()
	main.open_store()
	await _wait(0.8)
	await _shot("05_store")
	_close_overlays()
	main.open_ship_screen()
	await _wait(0.8)
	await _shot("06_ship_screen")
	_close_overlays()
	await _wait(0.5)
	main.start_fight("")
	main.battle.paused = false
	await _wait(1.0)
	await _shot("07_fight_start")
	for ship in main.encounter.living(0):
		for slot in ship.weapons:
			slot.target_ship = main.encounter.living(1)[0]
			slot.target_room = 0
			slot.autofire = true
	await _wait(12.0)
	await _shot("08_fight_mid")
	await _wait(25.0)
	await _shot("09_fight_late")
	print("outcome: ", main.encounter.outcome, " mawjig ", main.run.mawjig)
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _click_first_choice() -> void:
	for child in main.overlays.get_children():
		if child is EventWindow:
			for node in child.body.get_children():
				if node is Button:
					node.emit_signal("pressed")
					return


func _close_overlays() -> void:
	for child in main.overlays.get_children():
		child.queue_free()
