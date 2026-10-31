class_name ShipScreen
extends Overlay
## Between fights: upgrade systems and the reactor (or AZC), fit weapons from the hold to free mounts, and
## look after the crew: their skills, moving them between the squad's ships, or letting them go.

var run: RunState
var ship: Ship
var _content := VBoxContainer.new()


func open(run_state: RunState, selected: Ship) -> void:
	run = run_state
	ship = selected if selected and not selected.is_gone() else run.living_ships()[0]
	place_panel(1320, 0)
	body.add_child(_content)
	add_button("DONE", close)
	_rebuild()


func _rebuild() -> void:
	for child in _content.get_children():
		child.queue_free()
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	header.add_child(UiKit.title_label(ship.name.to_upper(), 30))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	for each in run.living_ships():
		if run.living_ships().size() > 1:
			var tab := UiKit.button(each.name, func(): ship = each; _rebuild(), 0)
			tab.disabled = each == ship
			header.add_child(tab)
	var money := UiKit.label("MAWJIG  " + Mawjig.format(run.mawjig), 26, Color("#ffd46b"))
	money.add_theme_font_override("font", UiKit.font_title())
	header.add_child(money)
	_content.add_child(header)
	_content.add_child(UiKit.label("%s · %s · hull %d / %d · %s" % [ship.design.class_text, ship.race.name, ship.hull, ship.max_hull, _power_text()], 17, UiColours.TEXT_DIM))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	_content.add_child(columns)
	columns.add_child(_systems_column())
	columns.add_child(_weapons_column())
	columns.add_child(_crew_column())


func _power_text() -> String:
	match ship.reactor_type:
		"pool":
			return "reactor %d bars" % ship.reactor_level
		"core":
			return "AZC level %d: %d systems at once" % [ship.reactor_level, ship.core_capacity()]
	return "self-powered systems"


func _column(title: String, width: float) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(width, 0)
	column.add_theme_constant_override("separation", 6)
	column.add_child(UiKit.label(title, 16, UiColours.ACCENT, true))
	return column


func _systems_column() -> VBoxContainer:
	var column := _column("SYSTEMS", 460)
	var reactor_price := ShipOutfitter.reactor_upgrade_price(ship)
	if ship.reactor_type != "none":
		var label := "Reactor: %d bars" % ship.reactor_level if ship.reactor_type == "pool" else "AZC: level %d" % ship.reactor_level
		column.add_child(_upgrade_row(label, ship.reactor_level, 25 if ship.reactor_type == "pool" else 5, reactor_price, func():
			if ShipOutfitter.upgrade_reactor(run, ship):
				Sfx.play("upgrade")
			_rebuild()))
	var systems := ship.systems.filter(func(s): return s.behaviour != "power_core")
	systems.sort_custom(func(a, b): return a.def.order < b.def.order)
	for system in systems:
		column.add_child(_upgrade_row(system.display_name(), system.level, system.def.max_level, ShipOutfitter.system_upgrade_price(system), func():
			if ShipOutfitter.upgrade_system(run, ship, system):
				Sfx.play("upgrade")
			_rebuild(), system.def.level_note(system.level)))
	return column


func _upgrade_row(label: String, level: int, max_level: int, price: int, on_upgrade: Callable, note: String = "") -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.box(UiColours.PANEL_LIGHT, UiColours.BORDER_DIM, 1, 4, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(UiKit.label(label, 17, UiColours.TEXT, true))
	var pips := HBoxContainer.new()
	pips.add_theme_constant_override("separation", 3)
	for index in mini(max_level, 25):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(10 if max_level <= 10 else 6, 10)
		pip.color = UiColours.POWER_GREEN if index < level else UiColours.BAR_EMPTY
		pips.add_child(pip)
	text.add_child(pips)
	if not note.is_empty():
		text.add_child(UiKit.label(note, 13, UiColours.TEXT_DIM))
	row.add_child(text)
	var button := UiKit.button("MAX" if price < 0 else "+%s" % Mawjig.format(price), on_upgrade, 100)
	button.disabled = price < 0 or run.mawjig < price
	button.add_theme_color_override("font_color", Color("#ffd46b"))
	row.add_child(button)
	return card


func _weapons_column() -> VBoxContainer:
	var column := _column("WEAPONS", 400)
	var weapons_system := ship.system_by("weapons")
	if weapons_system == null:
		column.add_child(UiKit.label("This ship has no Weapons system.", 16, UiColours.TEXT_DIM))
	for slot in ship.weapons.duplicate():
		if slot.def.type == "suit":
			continue
		var row := HBoxContainer.new()
		var name_label := UiKit.label("Mount %d: %s" % [slot.mount_id, slot.def.display_name()], 16)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.tooltip_text = slot.def.description + "\n" + slot.def.stat_line()
		name_label.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(name_label)
		row.add_child(UiKit.button("TO HOLD", func():
			ShipOutfitter.unfit_weapon(ship, slot)
			run.cargo.append(slot.def.id)
			_rebuild(), 110))
		column.add_child(row)
	column.add_child(UiKit.label("Free mounts: %d" % ShipOutfitter.free_mounts(ship).size(), 15, UiColours.TEXT_DIM))
	if not ship.suits.is_empty():
		column.add_child(UiKit.label("EVB suits: %s" % Library.weapon(ship.suits[0]).name, 16))
	column.add_child(UiKit.label("THE HOLD", 16, UiColours.ACCENT, true))
	if run.cargo.is_empty():
		column.add_child(UiKit.label("Empty.", 15, UiColours.TEXT_DIM))
	for index in run.cargo.size():
		var def := Library.weapon(run.cargo[index])
		if def == null:
			continue
		var row := HBoxContainer.new()
		var name_label := UiKit.label(def.display_name(), 16)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.tooltip_text = def.description + "\n" + def.stat_line()
		name_label.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(name_label)
		var fit := UiKit.button("FIT", func():
			if ShipOutfitter.fit_weapon(ship, def):
				run.cargo.remove_at(index)
			_rebuild(), 80)
		fit.disabled = ShipOutfitter.free_mounts(ship).is_empty() or weapons_system == null
		row.add_child(fit)
		column.add_child(row)
	return column


func _crew_column() -> VBoxContainer:
	var column := _column("CREW", 400)
	for member in ship.crew.duplicate():
		if member.dead:
			continue
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiKit.box(UiColours.PANEL_LIGHT, UiColours.BORDER_DIM, 1, 4, 8))
		var stack := VBoxContainer.new()
		card.add_child(stack)
		stack.add_child(UiKit.label("%s · %s · %d/%d" % [member.name, member.race.singular, int(member.health), int(member.max_health)], 16, UiColours.TEXT, true))
		var skills := PackedStringArray()
		for skill in CrewMember.SKILLS:
			var level: int = member.skill_level(skill)
			if level > 0 or member.xp[skill] >= 1.0:
				skills.append("%s %s" % [skill.capitalize(), ["·", "I", "II"][level]])
		stack.add_child(UiKit.label(", ".join(skills) if not skills.is_empty() else "No skills yet", 13, UiColours.TEXT_DIM))
		var buttons := HBoxContainer.new()
		for other in run.living_ships():
			if other != ship and other.living_crew_count() < EventRunner.MAX_CREW_PER_SHIP:
				buttons.add_child(UiKit.button("TO %s" % other.name.to_upper(), func():
					ship.crew.erase(member)
					other.add_crew(member)
					member.station_room = -1
					other.assign_stations()
					ship.assign_stations()
					_rebuild(), 0))
		if ship.living_crew_count() > 1:
			buttons.add_child(UiKit.button("DISMISS", func():
				ship.crew.erase(member)
				_rebuild(), 0))
		stack.add_child(buttons)
		column.add_child(card)
	return column
