## The title screen: the game's name over the collapse, a fan of cards, and the main choices.
class_name MenuScreen
extends Control

signal chosen(choice: String)


func _ready() -> void:
	var starfield := Starfield.new()
	starfield.collapse_center = Vector2(0.7, 0.45)
	starfield.collapse_size = 1.6
	add_child(starfield)

	_add_card_fan()

	var column := UiKit.vbox(14)
	column.position = Vector2(110, 150)
	column.custom_minimum_size = Vector2(420, 0)
	add_child(column)
	var eyebrow := UiKit.label("THE CORE HAS COLLAPSED", 15, UiKit.ACCENT, UiKit.display_font)
	column.add_child(eyebrow)
	var title := UiKit.label("INFALL", 108, UiKit.TEXT, UiKit.display_bold_font)
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	column.add_child(title)
	var subtitle := UiKit.label("DECK COLLAPSE", 34, UiKit.ACCENT, UiKit.display_font)
	column.add_child(subtitle)
	var blurb := UiKit.label("Ships fight with the cards their systems and crew put in the deck.\nBuild a ship, pick an enemy, and outplay their captain.", 16, UiKit.MUTED)
	column.add_child(blurb)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 18)
	column.add_child(spacer)
	column.add_child(_menu_button("Battle", "battle", true))
	column.add_child(_menu_button("Ship Designer", "designer"))
	column.add_child(_menu_button("How to Play", "rules"))
	column.add_child(_menu_button("Settings", "settings"))
	column.add_child(_menu_button("Quit", "quit"))
	var version := UiKit.label("Prototype · built in Godot · ships and rules are XML files you can edit", 12, UiKit.FAINT)
	version.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	version.position = Vector2(24, -34)
	add_child(version)


func _menu_button(text: String, choice: String, primary: bool = false) -> Button:
	var on_press := func(): chosen.emit(choice)
	var button := UiKit.primary_button(text, on_press, 24, 340) if primary else UiKit.button(text, on_press, 21, 340)
	button.custom_minimum_size.y = 52
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return button


## A loose fan of real cards falling toward the collapse, for the title art.
func _add_card_fan() -> void:
	var design: ShipDesign = Catalog.designs[0]
	for d in Catalog.designs:
		if d.name == "Wayfarer":
			design = d
	var ship := ShipState.new(0, design)
	var picks := [
		{"id": "weapon", "system": "weapons", "slot": 0}, {"id": "shield", "system": ""}, {"id": "power", "system": ""},
		{"id": "weapon", "system": "weapons", "slot": 1}, {"id": "repair", "system": ""},
	]
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(holder)
	for i in picks.size():
		var card: Dictionary = picks[i]
		if card.id == "weapon" and not ship.systems.has(card.system):
			continue
		var view := CardView.new().setup(card, CardLibrary.definition(card, ship.systems))
		view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		view.pivot_offset = CardView.BASE_SIZE / 2.0
		view.position = Vector2(860 + i * 120, 470 - abs(i - 2) * 30)
		view.rotation = (i - 2) * 0.16
		view.scale = Vector2.ONE * 1.05
		holder.add_child(view)
		var tween := view.create_tween().set_loops()
		tween.tween_property(view, "position:y", view.position.y - 10, 2.0 + i * 0.3).set_trans(Tween.TRANS_SINE)
		tween.tween_property(view, "position:y", view.position.y, 2.0 + i * 0.3).set_trans(Tween.TRANS_SINE)
