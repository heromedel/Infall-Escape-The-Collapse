## Draws every card once and saves a screenshot (tools/out/gallery.png). For checking card art headlessly.
extends Control


func _ready() -> void:
	theme = UiKit.theme()
	var background := ColorRect.new()
	background.color = UiKit.BACKGROUND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var design: ShipDesign = Catalog.designs[0]
	for d in Catalog.designs:
		if d.name == "Lattice":
			design = d
	var ship := ShipState.new(0, design)
	var definitions: Array = []
	for card_id in CardLibrary.FIXED_CARDS:
		definitions.append(CardLibrary.definition({"id": card_id, "system": ""}, ship.systems))
	var gallery_weapons := {"type": "weapon", "name": "Gallery", "weapons": Catalog.weapons.values().slice(0, 8)}
	ship.systems["gallery"] = gallery_weapons
	for slot in gallery_weapons.weapons.size():
		definitions.append(CardLibrary.definition({"id": "weapon", "system": "gallery", "slot": slot}, ship.systems))
	definitions.append(CardLibrary.definition({"id": "suit", "system": "dock"}, ship.systems))
	var x := 12.0
	var y := 12.0
	for definition in definitions:
		var view := CardView.new().setup({"uid": 0, "id": definition.id}, definition, "Gallery")
		view.position = Vector2(x, y)
		view.playable = definition.cost <= 1
		add_child(view)
		x += 190
		if x > 1500:
			x = 12
			y += 262
	var back := CardView.new()
	back.face_down = true
	back.owner_color = Color("#FF8500")
	back.position = Vector2(x, y)
	add_child(back)
	await get_tree().create_timer(0.3).timeout
	DirAccess.make_dir_recursive_absolute("res://tools/out")
	get_viewport().get_texture().get_image().save_png("res://tools/out/gallery.png")
	get_tree().quit()
