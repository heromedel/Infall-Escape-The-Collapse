extends Node
## Times how long a fight takes to start: the start_fight call itself and the frames right after it.
## Run with a display: xvfb-run godot --path . tools/fight_start_timing.tscn

var main: Node


func _ready() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RunState.SAVE_PATH))
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(1.0).timeout
	main.start_new_run("outrider")
	await get_tree().create_timer(1.5).timeout
	for squad in ["terran-pirates", "mecha-raiders", "terran-pirates"]:
		for child in main.overlays.get_children():
			child.queue_free()
		await get_tree().create_timer(0.5).timeout
		var started := Time.get_ticks_usec()
		main.start_fight(squad)
		var call_ms := (Time.get_ticks_usec() - started) / 1000.0
		var frames := PackedStringArray()
		var last := Time.get_ticks_usec()
		for index in 6:
			await RenderingServer.frame_post_draw
			var now := Time.get_ticks_usec()
			frames.append("%.0f" % ((now - last) / 1000.0))
			last = now
		print("fight %s: start_fight %.0f ms, next frames %s ms" % [squad, call_ms, ", ".join(frames)])
		await get_tree().create_timer(1.0).timeout
	get_tree().quit()
