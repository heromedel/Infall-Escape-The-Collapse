extends Node
func _ready():
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RunState.SAVE_PATH))
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(0.5).timeout
	main.start_new_run("outrider")
	await get_tree().create_timer(0.5).timeout
	for child in main.overlays.get_children():
		child.queue_free()
	main.run.mawjig = 5000
	main.open_store()
	await get_tree().create_timer(0.5).timeout
	var store: StoreWindow
	for child in main.overlays.get_children():
		if child is StoreWindow: store = child
	store._buy_system(Library.system("crew-teleporter"), 2178)
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/picker.png")
	var picker: RoomPicker
	for child in main.overlays.get_children():
		if child is RoomPicker: picker = child
	picker.picked.emit(4)
	await get_tree().create_timer(0.3).timeout
	var ship: Ship = main.run.squad[0]
	print("teleporter installed: ", ship.system_by("teleporter") != null, " in room ", ship.system_by("teleporter").room if ship.system_by("teleporter") else -1, " connected ", ship.system_connected(ship.system_by("teleporter")) if ship.system_by("teleporter") else false)
	get_tree().quit()
