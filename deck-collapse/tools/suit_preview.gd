## Screenshot of battlesuits out on both sides, to check the suit markers, their drift and the Recall button.
## Run: godot --path . res://tools/suit_preview.tscn   (writes tools/out/suits.png)
extends Control


func _ready() -> void:
	var player := _design("Lattice")
	var enemy := _design("Heavy Gunship")
	var screen := BattleScreen.new()
	screen.size = Vector2(1600, 900)
	add_child(screen)
	screen.start(player, enemy)
	await get_tree().create_timer(1.0).timeout
	var battle := screen.battle
	for side in 2:
		var dock := battle.ships[side].first_system_of_type("evb")
		for member in battle.living_crew_of(side):
			if member.ship == side and member.system != battle.ships[side].first_system_of_type("piloting"):
				var suit_id: String = battle.ships[side].systems[dock].suits[0]
				var action: String = Catalog.suit_kind(suit_id).action
				battle.ships[side].suits.append({"id": 900 + side, "kind": suit_id, "dock": dock, "pilot": member.id,
					"target": battle.ships[1 - side].system_order[2] if action in ["shoot", "board"] else "",
					"turns_left": 3, "air": 3, "recalling": false, "damaged": false, "ready": true})
				member.system = ""
				break
	screen._suit_layer.selected = 0
	await get_tree().create_timer(2.5).timeout
	DirAccess.make_dir_recursive_absolute("res://tools/out")
	get_viewport().get_texture().get_image().save_png("res://tools/out/suits.png")
	get_tree().quit()


func _design(design_name: String) -> ShipDesign:
	for design in Catalog.designs:
		if design.name == design_name:
			return design
	return Catalog.designs[0]
