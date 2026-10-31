extends Node2D
## Draws every race's crew tokens under both GATOS Species settings, at the ship's and the crew card's sizes, and
## saves the sheet to user://portrait_sheet.png. Run with a display:
## xvfb-run -a godot --path . --rendering-driver opengl3 tools/portrait_sheet.tscn

const NAMES := ["Ginger", "Sable", "Marlowe", "Vex", "Pip", "Index", "Ledger", "Juniper", "Tom Avery", "Kit-7"]


func _ready() -> void:
	get_window().size = Vector2i(1100, 760)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("user://portrait_sheet.png")
	print("saved ", ProjectSettings.globalize_path("user://portrait_sheet.png"))
	get_tree().quit()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1100, 760), Color("#0d1220"))
	var was: Variant = Settings.get_value("gatos_species")
	var y := 30.0
	for species in ["Terrans", "Tabbys"]:
		Settings._values["gatos_species"] = species
		draw_string(ThemeDB.fallback_font, Vector2(10, y), species, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		y += 20
		for race_id in ["terran", "mecha", "senti"]:
			draw_string(ThemeDB.fallback_font, Vector2(10, y + 34), race_id, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
			for index in NAMES.size():
				var centre := Vector2(110 + index * 95, y + 30)
				CrewPortraits.draw_token(self, race_id, NAMES[index], centre, 32, Color("#66ff66"))
				CrewPortraits.draw_token(self, race_id, NAMES[index], centre + Vector2(52, 20), 12.5, Color("#66ff66"))
			y += 80
		y += 20
	Settings._values["gatos_species"] = was
