extends Node2D
## Draws every ship design side by side and saves a picture: a quick look at hulls, floors and weapons.
## Run with a display: xvfb-run godot --path . tools/ship_gallery.tscn

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	var ships: Array = []
	var filter := OS.get_environment("ONLY")
	for id in Library.ships:
		if filter != "" and not id.contains(filter):
			continue
		ships.append(Ship.from_design(Library.ship(id), 0, rng))
	var encounter := Encounter.new()
	encounter.setup(ships, [], 1)
	var columns := 6
	var cell := Vector2(560, 820)
	for index in ships.size():
		var ship: Ship = ships[index]
		ship.world_position = Vector2((index % columns) * cell.x + cell.x * 0.5, (index / columns) * cell.y + cell.y * 0.5)
		var view := ShipView.new()
		view.setup(ship, encounter)
		add_child(view)
		var label := Label.new()
		label.text = ship.design.id
		label.position = ship.world_position + Vector2(-200, cell.y * 0.5 - 60)
		label.add_theme_font_size_override("font_size", 28)
		add_child(label)
	var camera := Camera2D.new()
	var rows := ceili(ships.size() / float(columns))
	camera.position = Vector2(columns * cell.x, rows * cell.y) * 0.5
	var fit := minf(1920.0 / (columns * cell.x), 1080.0 / (rows * cell.y))
	camera.zoom = Vector2.ONE * fit
	add_child(camera)
	camera.make_current()
	RenderingServer.set_default_clear_color(Color(0.03, 0.04, 0.07))
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/claude-0/gallery.png")
	get_tree().quit()
