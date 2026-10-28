## The Ship Designer: pick systems and their levels, weapons, suits, hull, missiles and crew. Shows the deck the
## design builds and its design points as you go. Designs save to the player's ships folder and export as XML.
class_name DesignerScreen
extends Control

signal fly(design: ShipDesign)
signal back

## Colours from the Infall palette (docs/art/palette.md), shown as swatches.
const PALETTE := {
	"Power green": "#66FF66", "Pirate orange": "#FF8500", "Mecha purple": "#AA28EB", "Tentauri pink": "#FF5ECA",
	"Azurethea blue": "#4F8FFF", "Senti-GPH yellow-green": "#D2FF00", "Whispwraith magenta": "#FF00E6",
	"Lykario silver": "#D1DBE7", "Malphen flesh": "#FFA480",
}

var design: ShipDesign

var _systems_box: VBoxContainer
var _crew_box: VBoxContainer
var _deck_grid: GridContainer
var _deck_title: Label
var _points_label: Label
var _problems_label: Label
var _status_label: Label
var _identity_box: VBoxContainer
var _file_dialog: FileDialog


func _ready() -> void:
	if design == null:
		design = Catalog.designs[0].duplicate_design()
	add_child(Starfield.new())
	var root := UiKit.vbox(12)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 22
	root.offset_top = 18
	root.offset_right = -22
	root.offset_bottom = -18
	add_child(root)

	var top := UiKit.hbox(14)
	top.add_child(UiKit.button("‹ Back", func(): back.emit(), 17))
	var title := UiKit.heading("SHIP DESIGNER", 34)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var presets := OptionButton.new()
	presets.add_item("Start from a ship…")
	for d in Catalog.designs:
		presets.add_item(d.name + ("" if d.built_in else " (yours)"))
	presets.item_selected.connect(func(index):
		if index > 0:
			design = Catalog.designs[index - 1].duplicate_design()
			_rebuild_all())
	top.add_child(presets)
	top.add_child(UiKit.button("Blank Ship", _new_blank, 15))
	root.add_child(top)

	var columns := UiKit.hbox(16)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(columns)
	columns.add_child(_build_identity_column())
	columns.add_child(_build_systems_column())
	columns.add_child(_build_deck_column())

	_file_dialog = FileDialog.new()
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.use_native_dialog = true
	_file_dialog.filters = PackedStringArray(["*.xml ; Ship XML"])
	add_child(_file_dialog)
	_rebuild_all()


# ---------------------------------------------------------------- columns

func _build_identity_column() -> Control:
	var panel := UiKit.panel(Color(0.06, 0.08, 0.13, 0.92))
	panel.custom_minimum_size = Vector2(330, 0)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	_identity_box = UiKit.vbox(10)
	_identity_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(UiKit.margin(_identity_box, 6))
	return panel


func _build_systems_column() -> Control:
	var panel := UiKit.panel(Color(0.06, 0.08, 0.13, 0.92))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var box := UiKit.vbox(10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(UiKit.margin(box, 6))
	box.add_child(UiKit.heading("SYSTEMS", 20, UiKit.ACCENT))
	box.add_child(_hint("Each system adds its cards to the deck. Its level is how much power its cards can use per turn."))
	_systems_box = UiKit.vbox(6)
	box.add_child(_systems_box)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	box.add_child(spacer)
	box.add_child(UiKit.heading("CREW", 20, UiKit.ACCENT))
	box.add_child(_hint("Each crew member adds Repair, Extinguish Fire and (with Airlock Control) Cycle Airlock. Their station is where they start."))
	_crew_box = UiKit.vbox(6)
	box.add_child(_crew_box)
	return panel


func _build_deck_column() -> Control:
	var panel := UiKit.panel(Color(0.06, 0.08, 0.13, 0.92))
	panel.custom_minimum_size = Vector2(318, 0)
	var box := UiKit.vbox(8)
	panel.add_child(UiKit.margin(box, 6))
	_deck_title = UiKit.heading("DECK", 20, UiKit.ACCENT)
	box.add_child(_deck_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_deck_grid = GridContainer.new()
	_deck_grid.columns = 3
	_deck_grid.add_theme_constant_override("h_separation", 6)
	_deck_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(_deck_grid)
	box.add_child(scroll)
	return panel


# ---------------------------------------------------------------- building rows

func _rebuild_all() -> void:
	_rebuild_identity()
	_rebuild_systems()
	_rebuild_crew()
	_refresh_summary()


func _rebuild_identity() -> void:
	for child in _identity_box.get_children():
		child.queue_free()
	_identity_box.add_child(UiKit.heading("SHIP", 20, UiKit.ACCENT))
	_identity_box.add_child(_field("Name", design.name, func(text): design.name = text; _refresh_summary()))
	_identity_box.add_child(_field("Faction", design.faction, func(text): design.faction = text))
	_identity_box.add_child(UiKit.label("Colour", 14, UiKit.MUTED))
	var swatches := HFlowContainer.new()
	swatches.add_theme_constant_override("h_separation", 6)
	swatches.add_theme_constant_override("v_separation", 6)
	for colour_name in PALETTE:
		var hex: String = PALETTE[colour_name]
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(30, 30)
		swatch.tooltip_text = colour_name
		var chosen := design.color.to_upper() == hex.to_upper()
		swatch.add_theme_stylebox_override("normal", UiKit.box(Color(hex), Color.WHITE if chosen else Color(hex).darkened(0.4), 15, 3 if chosen else 1))
		swatch.add_theme_stylebox_override("hover", UiKit.box(Color(hex).lightened(0.2), Color.WHITE, 15, 2))
		swatch.pressed.connect(func():
			Sounds.play("click")
			design.color = hex
			_rebuild_identity()
			_refresh_summary())
		swatches.add_child(swatch)
	_identity_box.add_child(swatches)
	_identity_box.add_child(_stepper_row("Hull", design.hull, 4, 60, func(v): design.hull = v))
	_identity_box.add_child(_stepper_row("Missiles", design.missiles, 0, 30, func(v): design.missiles = v))
	_identity_box.add_child(UiKit.label("Note", 14, UiKit.MUTED))
	var note := TextEdit.new()
	note.text = design.note
	note.custom_minimum_size = Vector2(0, 70)
	note.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	note.text_changed.connect(func(): design.note = note.text)
	_identity_box.add_child(note)

	_points_label = UiKit.heading("", 22, UiKit.TEXT)
	_identity_box.add_child(_points_label)
	_problems_label = UiKit.label("", 14, UiKit.DANGER)
	_problems_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_identity_box.add_child(_problems_label)

	var buttons := GridContainer.new()
	buttons.columns = 2
	buttons.add_theme_constant_override("h_separation", 8)
	buttons.add_theme_constant_override("v_separation", 8)
	for spec in [["Save to My Ships", _save], ["Export XML…", _export], ["Import XML…", _import], ["Copy XML", _copy_xml]]:
		var button := UiKit.button(spec[0], spec[1], 15)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buttons.add_child(button)
	_identity_box.add_child(buttons)
	var fly_button := UiKit.primary_button("FLY THIS SHIP", _fly, 20)
	fly_button.custom_minimum_size.y = 48
	_identity_box.add_child(fly_button)
	_status_label = UiKit.label("", 13, UiKit.GOOD)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_identity_box.add_child(_status_label)
	_identity_box.add_child(_hint("My Ships folder: " + ProjectSettings.globalize_path(Catalog.USER_SHIPS_FOLDER)))
	_identity_box.add_child(UiKit.button("Open My Ships Folder", func(): OS.shell_open(ProjectSettings.globalize_path(Catalog.USER_SHIPS_FOLDER)), 14))


func _rebuild_systems() -> void:
	for child in _systems_box.get_children():
		child.queue_free()
	var color := Color.from_string(design.color, UiKit.GOOD)
	for system in design.systems:
		_systems_box.add_child(_system_row(system, color))
	var add_row := UiKit.hbox(8)
	var adder := OptionButton.new()
	adder.add_item("+ Add a system…")
	var addable: Array = []
	for type in Catalog.systems:
		if type == "weapon" or type == "evb" or not design.has_system(type):
			addable.append(type)
			adder.add_item(Catalog.systems[type].name)
	adder.item_selected.connect(func(index):
		if index > 0:
			_add_system(addable[index - 1]))
	add_row.add_child(adder)
	_systems_box.add_child(add_row)


func _system_row(system: Dictionary, color: Color) -> Control:
	var definition: Dictionary = Catalog.systems[system.type]
	var panel := UiKit.panel(UiKit.PANEL_LIGHT, UiKit.LINE, 8)
	var row := UiKit.hbox(10)
	panel.add_child(row)
	var icon := IconSwatch.new()
	icon.art = IconPainter.system_art(system)
	icon.color = color
	icon.icon_size = 24
	icon.custom_minimum_size = Vector2(30, 30)
	row.add_child(icon)
	var name_label := UiKit.label("Weapon" if system.type == "weapon" else definition.name, 16, UiKit.TEXT, UiKit.display_font)
	name_label.custom_minimum_size = Vector2(118, 0)
	name_label.clip_text = true
	name_label.tooltip_text = definition.summary
	name_label.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(name_label)
	if system.type == "weapon":
		var name_edit := LineEdit.new()
		name_edit.text = system.name
		name_edit.custom_minimum_size = Vector2(120, 0)
		name_edit.text_changed.connect(func(text): system.name = text; _refresh_summary())
		row.add_child(name_edit)
		var kinds := OptionButton.new()
		var kind_ids := Catalog.weapon_kinds.keys()
		for kind_id in kind_ids:
			kinds.add_item(Catalog.weapon_kinds[kind_id].name)
		kinds.select(kind_ids.find(system.kind))
		kinds.tooltip_text = Catalog.weapon_kind(system.kind).summary
		kinds.item_selected.connect(func(index):
			system.kind = kind_ids[index]
			_rebuild_systems()
			_refresh_summary())
		row.add_child(kinds)
		kinds.custom_minimum_size = Vector2(130, 0)
		row.add_child(_stepper("Type", system.weapon_type, 1, 3, func(v):
			system.weapon_type = v
			system.level = maxi(system.level, v)))
	elif system.type == "evb":
		var suits := OptionButton.new()
		var suit_ids := Catalog.suit_kinds.keys()
		for suit_id in suit_ids:
			suits.add_item("%s (cost %d)" % [Catalog.suit_kinds[suit_id].name, Catalog.suit_kinds[suit_id].cost])
		suits.select(suit_ids.find(system.suit))
		suits.tooltip_text = Catalog.suit_kind(system.suit).summary
		suits.item_selected.connect(func(index):
			system.suit = suit_ids[index]
			system.level = maxi(system.level, Catalog.suit_kind(system.suit).cost)
			_rebuild_systems()
			_refresh_summary())
		row.add_child(suits)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(_stepper("Level", system.level, definition.min_level, definition.max_level, func(v): system.level = v))
	if not definition.required:
		var remove := UiKit.button("✕", func(): _remove_system(system), 15)
		remove.tooltip_text = "Remove this system"
		row.add_child(remove)
	return panel


func _rebuild_crew() -> void:
	for child in _crew_box.get_children():
		child.queue_free()
	for member in design.crew:
		var panel := UiKit.panel(UiKit.PANEL_LIGHT, UiKit.LINE, 8)
		var row := UiKit.hbox(10)
		panel.add_child(row)
		var name_edit := LineEdit.new()
		name_edit.text = member.name
		name_edit.custom_minimum_size = Vector2(180, 0)
		name_edit.text_changed.connect(func(text): member.name = text)
		row.add_child(name_edit)
		var skill := OptionButton.new()
		for skill_name in Battle.SKILL_NAMES:
			skill.add_item(skill_name)
		skill.select(member.skill)
		skill.tooltip_text = "Crew skill raises the bonus they give the system they man."
		skill.item_selected.connect(func(index): member.skill = index; _refresh_summary())
		row.add_child(skill)
		row.add_child(UiKit.label("starts at", 14, UiKit.MUTED))
		var station := OptionButton.new()
		var ids: Array = design.systems.map(func(s): return s.id)
		for system in design.systems:
			station.add_item(system.get("name", Catalog.systems[system.type].name) if system.type == "weapon" else Catalog.systems[system.type].name)
		station.select(maxi(0, ids.find(member.station)))
		station.item_selected.connect(func(index): member.station = ids[index])
		row.add_child(station)
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
		row.add_child(UiKit.button("✕", func():
			design.crew.erase(member)
			_rebuild_crew()
			_refresh_summary(), 15))
		_crew_box.add_child(panel)
	if design.crew.size() < 8:
		_crew_box.add_child(UiKit.button("+ Add crew member", _add_crew, 15))


func _refresh_summary() -> void:
	if _points_label == null:
		return
	var points := design.points()
	var budget := Settings.budget_limit()
	_points_label.text = "%d DESIGN POINTS" % points + ("" if budget == 0 else "  /  %d" % budget)
	_points_label.add_theme_color_override("font_color", UiKit.DANGER if budget > 0 and points > budget else UiKit.TEXT)
	var problems := design.problems()
	if budget > 0 and points > budget:
		problems.append("Over the %d point budget (Settings)." % budget)
	_problems_label.text = "\n".join(problems.map(func(p): return "• " + p))
	_refresh_deck()


func _refresh_deck() -> void:
	for child in _deck_grid.get_children():
		child.queue_free()
	var summary := CardLibrary.deck_summary(design)
	var total := 0
	var ship := ShipState.new(0, design)
	for entry in summary:
		total += entry.count
		var card := {"uid": 0, "id": entry.entry.id, "system": entry.entry.system, "temporary": false}
		var holder := Control.new()
		holder.custom_minimum_size = CardView.BASE_SIZE * 0.5
		var view := CardView.new().setup(card, CardLibrary.definition(card, ship.systems))
		view.scale = Vector2.ONE * 0.5
		view.count_badge = entry.count
		view.tooltip_text = "%s ×%d\n%s" % [view.definition.name, entry.count, view.definition.text]
		holder.add_child(view)
		_deck_grid.add_child(holder)
	_deck_title.text = "DECK · %d CARDS" % total


# ---------------------------------------------------------------- editing

func _add_system(type: String) -> void:
	var definition: Dictionary = Catalog.systems[type]
	var system := {"type": type, "level": definition.min_level, "id": type}
	if type == "weapon":
		system.id = _unique_id("weapon")
		system.kind = "laser"
		system.weapon_type = 1
		system.name = "Pulse Laser"
	elif type == "evb":
		system.id = _unique_id("dock")
		system.suit = "assault"
		system.level = Catalog.suit_kind("assault").cost
	design.systems.append(system)
	Sounds.play("click")
	_rebuild_systems()
	_rebuild_crew()
	_refresh_summary()


func _remove_system(system: Dictionary) -> void:
	design.systems.erase(system)
	for member in design.crew:
		if member.station == system.id and not design.systems.is_empty():
			member.station = design.systems[0].id
	_rebuild_systems()
	_rebuild_crew()
	_refresh_summary()


func _add_crew() -> void:
	var names := ["Ada", "Bram", "Cass", "Dov", "Esme", "Finn", "Gale", "Hux", "Ines", "Jory", "Kael", "Lio"]
	var station: String = design.systems[0].id if not design.systems.is_empty() else ""
	design.crew.append({"name": names[design.crew.size() % names.size()], "skill": 0, "station": station})
	_rebuild_crew()
	_refresh_summary()


func _new_blank() -> void:
	design = ShipDesign.new()
	design.name = "New Ship"
	design.faction = "Colony Fleet"
	design.hull = 30
	for type in ["reactor", "shields", "engines", "piloting", "sensors", "lifeSupport", "medBay"]:
		var level: int = 6 if type == "reactor" else 1
		design.systems.append({"type": type, "level": level, "id": type})
	design.systems.append({"type": "weapon", "id": "weapon-1", "kind": "laser", "weapon_type": 2, "level": 2, "name": "Pulse Laser"})
	design.crew = [{"name": "Ada", "skill": 1, "station": "piloting"}, {"name": "Bram", "skill": 0, "station": "weapon-1"}]
	_rebuild_all()


func _unique_id(prefix: String) -> String:
	var n := 1
	while not design.system_by_id("%s-%d" % [prefix, n]).is_empty():
		n += 1
	return "%s-%d" % [prefix, n]


# ---------------------------------------------------------------- saving and files

func _save() -> void:
	var path := Catalog.save_user_design(design)
	_status("Saved to " + ProjectSettings.globalize_path(path))


func _export() -> void:
	_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_file_dialog.title = "Export ship XML"
	_file_dialog.current_file = Catalog.file_name_for(design.name) + ".xml"
	_disconnect_dialog()
	_file_dialog.file_selected.connect(func(path):
		if Catalog.write_text_file(path, design.to_xml()):
			_status("Exported to " + path)
		else:
			_status("Couldn't write " + path, true))
	_file_dialog.popup_centered_ratio(0.7)


func _import() -> void:
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.title = "Import ship XML"
	_disconnect_dialog()
	_file_dialog.file_selected.connect(func(path):
		var loaded := ShipDesign.from_xml(FileAccess.get_file_as_string(path))
		if loaded == null:
			_status("That file isn't a ship XML.", true)
			return
		design = loaded
		_rebuild_all()
		_status("Imported " + path))
	_file_dialog.popup_centered_ratio(0.7)


func _copy_xml() -> void:
	DisplayServer.clipboard_set(design.to_xml())
	_status("Ship XML copied to the clipboard.")


func _fly() -> void:
	var problems := design.problems()
	if not problems.is_empty():
		Sounds.play("error")
		_status("Fix these first: " + " ".join(problems), true)
		return
	Catalog.save_user_design(design)
	fly.emit(design)


func _disconnect_dialog() -> void:
	for connection in _file_dialog.file_selected.get_connections():
		_file_dialog.file_selected.disconnect(connection.callable)


func _status(text: String, is_error: bool = false) -> void:
	_status_label.text = text
	_status_label.add_theme_color_override("font_color", UiKit.DANGER if is_error else UiKit.GOOD)
	Sounds.play("error" if is_error else "power")


# ---------------------------------------------------------------- small widgets

func _field(label_text: String, value: String, on_change: Callable) -> Control:
	var row := UiKit.hbox(8)
	var label := UiKit.label(label_text, 14, UiKit.MUTED)
	label.custom_minimum_size = Vector2(70, 0)
	row.add_child(label)
	var edit := LineEdit.new()
	edit.text = value
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_changed.connect(on_change)
	row.add_child(edit)
	return row


func _stepper_row(label_text: String, value: int, low: int, high: int, on_change: Callable) -> Control:
	var row := UiKit.hbox(8)
	var label := UiKit.label(label_text, 14, UiKit.MUTED)
	label.custom_minimum_size = Vector2(70, 0)
	row.add_child(label)
	row.add_child(_stepper("", value, low, high, on_change))
	return row


## [-] value [+] with limits. Calls on_change(new value), then refreshes the summary.
func _stepper(label_text: String, value: int, low: int, high: int, on_change: Callable) -> Control:
	var row := UiKit.hbox(4)
	if label_text != "":
		row.add_child(UiKit.label(label_text, 13, UiKit.MUTED))
	var shown := UiKit.label(str(value), 17, UiKit.TEXT, UiKit.display_bold_font)
	shown.custom_minimum_size = Vector2(30, 0)
	shown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var current := [value]
	var change := func(delta: int):
		var next := clampi(current[0] + delta, low, high)
		if next == current[0]:
			Sounds.play("error", -6.0)
			return
		current[0] = next
		shown.text = str(next)
		on_change.call(next)
		_rebuild_systems()
		_refresh_summary()
	var minus := UiKit.button("−", func(): change.call(-1), 16)
	var plus := UiKit.button("+", func(): change.call(1), 16)
	minus.custom_minimum_size = Vector2(32, 30)
	plus.custom_minimum_size = Vector2(32, 30)
	row.add_child(minus)
	row.add_child(shown)
	row.add_child(plus)
	return row


func _hint(text: String) -> Label:
	var label := UiKit.label(text, 13, UiKit.MUTED)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
