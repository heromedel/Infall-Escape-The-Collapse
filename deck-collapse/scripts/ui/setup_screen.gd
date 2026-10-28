## Pick your ship and the enemy's, see what each brings, then fight. "Customize" opens a copy in the designer.
class_name SetupScreen
extends Control

signal fight(player: ShipDesign, enemy: ShipDesign)
signal customize(design: ShipDesign)
signal back

var player_design: ShipDesign
var enemy_design: ShipDesign
var _previews: Array[VBoxContainer] = []
var _lists: Array[VBoxContainer] = []


func _ready() -> void:
	add_child(Starfield.new())
	var root := UiKit.vbox(14)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		root.set("offset_" + side, 28 if side in ["left", "top"] else -28)
	add_child(root)

	var top := UiKit.hbox(16)
	top.add_child(UiKit.button("‹ Back", func(): back.emit(), 17))
	var title := UiKit.heading("CHOOSE YOUR BATTLE", 34)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var hint := UiKit.label("Ships in green are cruisers (hull 30). Orange ships are enemy classes: smaller, but a quicker fight.", 14, UiKit.MUTED)
	top.add_child(hint)
	root.add_child(top)

	var columns := UiKit.hbox(24)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(columns)
	for side in 2:
		columns.add_child(_build_column(side))

	var bottom := UiKit.hbox(14)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_child(UiKit.button("Customize My Ship", func(): customize.emit(player_design), 18, 220))
	bottom.add_child(UiKit.button("Random Enemy", _pick_random_enemy, 18, 180))
	var fight_button := UiKit.primary_button("FIGHT", func(): fight.emit(player_design, enemy_design), 26, 260)
	fight_button.custom_minimum_size.y = 56
	bottom.add_child(fight_button)
	root.add_child(bottom)
	_refresh()


func _build_column(side: int) -> Control:
	var panel := UiKit.panel(Color(0.06, 0.08, 0.13, 0.9))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := UiKit.vbox(10)
	panel.add_child(UiKit.margin(box, 8))
	box.add_child(UiKit.heading("YOUR SHIP" if side == 0 else "ENEMY SHIP", 22, UiKit.GOOD if side == 0 else Color("#FF8500")))
	var split := UiKit.hbox(14)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(split)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(250, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := UiKit.vbox(6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	split.add_child(scroll)
	_lists.append(list)
	var preview := UiKit.vbox(8)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(preview)
	_previews.append(preview)
	return panel


func _refresh() -> void:
	for side in 2:
		var list := _lists[side]
		for child in list.get_children():
			child.queue_free()
		var chosen := player_design if side == 0 else enemy_design
		for design in Catalog.designs:
			list.add_child(_ship_button(design, side, design == chosen or design.name == chosen.name and design.source_path == chosen.source_path))
		_show_preview(_previews[side], chosen)


func _ship_button(design: ShipDesign, side: int, selected: bool) -> Button:
	var color := Color.from_string(design.color, UiKit.GOOD)
	var button := UiKit.button("%s\n%s · hull %d · worth %s%s" % [design.name, design.faction, design.hull, Money.text(design.total_cost()),
		"" if design.built_in else " · yours"], func():
			if side == 0:
				player_design = design
			else:
				enemy_design = design
			_refresh(), 15)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(240, 54)
	button.add_theme_font_override("font", UiKit.body_font)
	var style := UiKit.box(Color(color, 0.16) if selected else UiKit.PANEL_LIGHT, color if selected else Color(color, 0.35), 6, 2 if selected else 1)
	style.border_width_left = 5
	button.add_theme_stylebox_override("normal", style)
	return button


func _show_preview(box: VBoxContainer, design: ShipDesign) -> void:
	for child in box.get_children():
		child.queue_free()
	var color := Color.from_string(design.color, UiKit.GOOD)
	box.add_child(UiKit.heading(design.name.to_upper(), 26, color))
	var note := UiKit.label(design.note, 15, UiKit.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)
	var stats := "Hull %d   ·   Reactor %d   ·   Crew %d   ·   Deck %d cards" % [design.hull,
		_level_of(design, "reactor"), design.crew.size(), CardLibrary.deck_list(design).size()]
	if design.missiles > 0:
		stats += "   ·   %d missiles" % design.missiles
	box.add_child(UiKit.label(stats, 15, UiKit.TEXT, UiKit.body_bold_font))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 4)
	for system in design.systems:
		grid.add_child(_system_line(system, color))
	box.add_child(grid)
	var crew_names: Array = design.crew.map(func(m): return "%s (%s)" % [m.name, CrewSkills.summary(m.skills)])
	var crew_label := UiKit.label("Crew: " + ", ".join(crew_names), 14, UiKit.MUTED)
	crew_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(crew_label)


func _system_line(system: Dictionary, color: Color) -> Control:
	var row := UiKit.hbox(8)
	var icon := IconSwatch.new()
	icon.art = IconPainter.system_art(system)
	icon.color = color
	row.add_child(icon)
	var text: String = Catalog.systems[system.type].name
	if system.type == "weapon":
		text = "%s · %s T%d" % [system.name, Catalog.weapon_kind(system.kind).name, system.weapon_type]
	elif system.type == "evb":
		text = "EVB Dock · " + Catalog.suit_kind(system.suit).name
	row.add_child(UiKit.label("%s  [%d]" % [text, system.level], 14, UiKit.TEXT))
	return row


func _level_of(design: ShipDesign, type: String) -> int:
	for system in design.systems:
		if system.type == type:
			return system.level
	return 0


func _pick_random_enemy() -> void:
	var others := Catalog.designs.filter(func(d): return d != enemy_design)
	enemy_design = others[randi() % others.size()]
	_refresh()
