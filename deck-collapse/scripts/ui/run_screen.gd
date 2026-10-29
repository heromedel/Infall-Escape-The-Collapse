## Between battles in a run: what the last battle paid, then the stop. Three columns: the ship (its state, weapons
## and cargo hold), the station's store when the stop has one, and upgrades. Then on to a random enemy.
class_name RunScreen
extends Control

signal next_battle
signal end_run

var run: RunState
var _body: VBoxContainer
## What the mouse is over, explained at the bottom.
var _info: Label


func _ready() -> void:
	add_child(Starfield.new())
	_body = UiKit.vbox(12)
	var margin := UiKit.margin(_body, 24)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	_rebuild()


func _rebuild() -> void:
	for child in _body.get_children():
		child.queue_free()
	_body.add_child(_header())
	var columns := UiKit.hbox(16)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(_column("SHIP", _ship_column()))
	columns.add_child(_column("STATION" if run.station else "NO STATION HERE", _station_column()))
	columns.add_child(_column("UPGRADES", _upgrade_column()))
	_body.add_child(columns)
	_info = UiKit.label("Hover an item for details.", 14, UiKit.MUTED)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size.y = 40
	_body.add_child(_info)
	var buttons := UiKit.hbox(12)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	var problems := run.design.problems()
	var go := UiKit.primary_button("NEXT BATTLE (random enemy)", func(): next_battle.emit(), 20)
	go.custom_minimum_size.y = 50
	go.disabled = not problems.is_empty()
	go.tooltip_text = "\n".join(problems)
	buttons.add_child(go)
	buttons.add_child(UiKit.button("End Run", func(): end_run.emit(), 18))
	_body.add_child(buttons)


func _header() -> Control:
	var box := UiKit.vbox(4)
	var top := UiKit.hbox(12)
	var title := UiKit.heading("STATION" if run.station else "BETWEEN BATTLES", 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	top.add_child(UiKit.heading(Money.text(run.mawjig), 30, UiKit.ACCENT))
	box.add_child(top)
	var result: Dictionary = run.last_result
	var summary := "Battle %d against %s: " % [run.battles_fought, result.get("enemy", "?")]
	match result.get("outcome", ""):
		Battle.OUTCOME_DESTROYED: summary += "destroyed it."
		Battle.OUTCOME_CREW_LOST: summary += "killed its crew."
		_: summary += "no salvage."
	summary += "   Shots -%s  ·  Salvage +%s  ·  Jump -%s  ·  Battles won: %d" % [Money.text(result.get("spent", 0.0)),
		Money.text(result.get("reward", 0.0)), Money.text(result.get("jump_cost", 0.0)), run.battles_won]
	box.add_child(UiKit.label(summary, 15, UiKit.MUTED))
	return box


## A titled, scrolling column.
func _column(title: String, content: Control) -> Control:
	var panel := UiKit.panel(Color(0.06, 0.08, 0.13, 0.95))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box := UiKit.vbox(8)
	box.add_child(UiKit.heading(title, 20, UiKit.ACCENT))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	box.add_child(scroll)
	panel.add_child(UiKit.margin(box, 12))
	return panel


# ---------------------------------------------------------------- the ship

func _ship_column() -> Control:
	var box := UiKit.vbox(6)
	var color := Color.from_string(run.design.color, UiKit.GOOD)
	box.add_child(UiKit.heading(run.design.name.to_upper(), 20, color))
	var status := "Hull %d / %d" % [run.hull(), run.hull_max()]
	if run.uses_missiles():
		status += "  ·  %d missiles" % int(run.carry.get("missiles", 0))
	if run.uses_suit_parts():
		status += "  ·  %d suit parts" % int(run.carry.get("suit_parts", 0))
	box.add_child(UiKit.label(status, 16, UiKit.TEXT, UiKit.body_bold_font))
	var damaged: Array[String] = []
	for system_id in run.carry.get("systems", {}):
		var saved: Dictionary = run.carry.systems[system_id]
		var notes: Array[String] = []
		if saved.damage > 0:
			notes.append("%d damaged" % saved.damage)
		if saved.on_fire:
			notes.append("on fire")
		if saved.breached:
			notes.append("breached")
		if not notes.is_empty():
			damaged.append("%s (%s)" % [_system_name(run.design.system_by_id(system_id)), ", ".join(notes)])
	box.add_child(_wrapped("Systems: " + (", ".join(damaged) if not damaged.is_empty() else "all working"), 14,
		UiKit.DANGER if not damaged.is_empty() else UiKit.MUTED))
	var crew_names: Array = run.carry.get("crew", []).map(func(m): return "%s (%d/%d)" % [m.name,
		Battle.WOUNDS_TO_DIE - int(m.wounds), Battle.WOUNDS_TO_DIE])
	box.add_child(_wrapped("Crew: " + ", ".join(crew_names), 14, UiKit.MUTED))

	for system in run.weapon_systems():
		box.add_child(UiKit.heading("%s  ·  power %d  ·  %d / %d slots" % [system.name.to_upper(), system.level,
			system.weapons.size(), system.get("max_slots", Weapons.SLOTS_PER_SYSTEM)], 16, UiKit.TEXT))
		var reason := run.why_cannot_remove_weapon()
		for slot in system.weapons.size():
			var weapon: Dictionary = system.weapons[slot]
			var row := _row("%s · %s" % [weapon.name, Weapons.summary(weapon)], _weapon_detail(weapon))
			_add_action(row, "To cargo", func(): run.store_weapon(system.id, slot),
				reason if reason != "" else ("The cargo hold is full." if run.cargo_full() else ""))
			if run.station:
				_add_action(row, "Sell %s" % Money.text(RunState.sell_price({"kind": "weapon", "weapon": weapon})),
					func(): run.sell_weapon(system.id, slot), reason)
			box.add_child(row)

	box.add_child(UiKit.heading("CARGO  %d / %d" % [run.cargo.size(), run.cargo_slots()], 16, UiKit.TEXT))
	if run.cargo.is_empty():
		box.add_child(UiKit.label("Empty. Weapons and battlesuits here add no cards.", 13, UiKit.FAINT))
	for index in run.cargo.size():
		var item: Dictionary = run.cargo[index]
		var row := _row(item.name, _cargo_detail(item))
		for target in run.cargo_targets(index):
			_add_action(row, target.label, func(): run.use_cargo(index, target.target), "")
		if run.station:
			_add_action(row, "Sell %s" % Money.text(RunState.sell_price(item)), func(): run.sell_cargo(index), "")
		box.add_child(row)
	return box


func _cargo_detail(item: Dictionary) -> String:
	if item.kind == "weapon":
		return _weapon_detail(item.weapon)
	var suit := Catalog.suit_kind(item.suit)
	return "Needs an EVB Dock of level %d. %s" % [suit.cost, suit.summary]


# ---------------------------------------------------------------- the station

func _station_column() -> Control:
	var box := UiKit.vbox(6)
	if run.station == null:
		var gap := run.stops_to_next_station()
		box.add_child(_wrapped("This stop has no station: nothing to buy or sell. The next station is %s." % (
			"at the next stop" if gap <= 1 else "%d stops away" % gap), 14, UiKit.MUTED))
		box.add_child(_wrapped("You can still move weapons and battlesuits in and out of cargo.", 14, UiKit.MUTED))
		return box
	var missing := run.hull_max() - run.hull()
	var always := UiKit.vbox(6)
	_add_buy(always, "Repair 1 hull", "", run.hull_repair_price(), "Hull is full." if missing <= 0 else "",
		func(): run.repair_hull(1))
	if missing > 1:
		_add_buy(always, "Repair all hull (%d)" % missing, "", run.hull_repair_price() * missing, "",
			func(): run.repair_hull(missing))
	if run.uses_missiles():
		_add_buy(always, "1 missile", "", run.missile_price(), "", func(): run.buy_missile())
	if run.uses_suit_parts():
		_add_buy(always, "1 suit part", "", run.suit_part_price(), "", func(): run.buy_suit_part())
	if Settings.value("store_system_repair") == "On":
		var count := run.system_repair_count()
		_add_buy(always, "Repair all systems (%d)" % count, "Fixes system damage, fires and breaches.",
			run.system_repair_price() * count, "Nothing to fix." if count == 0 else "", func(): run.repair_all_systems())
	box.add_child(always)
	for section in run.station.sections:
		box.add_child(UiKit.heading(Station.SECTION_NAMES[section.id].to_upper(), 16, UiKit.TEXT))
		for item in section.items:
			var detail: String = item.detail
			if item.kind == "weapon":
				detail = "Goes into a free weapon slot, or cargo. " + detail
			elif item.kind == "suit":
				detail = "Goes to cargo; swap it into an EVB Dock from there. " + detail
			elif item.kind == "system":
				detail = "Installed at level 1. " + detail
			var title: String = item.name
			if item.kind == "crew" and item.detail != "Untrained.":
				title += " · " + item.detail.trim_suffix(".")
			_add_buy(box, title, detail, item.price, run.why_cannot_buy(item), func(): run.buy(item))
	return box


# ---------------------------------------------------------------- upgrades

func _upgrade_column() -> Control:
	var box := UiKit.vbox(6)
	var reason := run.why_cannot_upgrade_here()
	if reason != "":
		box.add_child(_wrapped(reason, 14, UiKit.MUTED))
	for system in run.design.systems:
		var definition: Dictionary = Catalog.systems[system.type]
		var price := RunState.upgrade_price(system)
		var row := _row("%s · Lv %d / %d" % [_system_name(system), system.level, definition.max_level], definition.summary)
		var why := reason
		if why == "" and price < 0.0:
			why = "At its top level."
		elif why == "" and not run.can_afford(price):
			why = "Not enough Mawjig."
		_add_action(row, "+1  %s" % (Money.text(price) if price >= 0.0 else "max"), func(): run.upgrade(system.id), why)
		box.add_child(row)
	var undo := UiKit.button("Undo last upgrade", func():
		run.undo_upgrade()
		_rebuild(), 14)
	undo.disabled = not run.can_undo_upgrade()
	box.add_child(undo)
	return box


# ---------------------------------------------------------------- pieces

func _weapon_detail(weapon: Dictionary) -> String:
	return "%d power, %d card%s in the deck (speed). %s" % [weapon.power, weapon.speed, "" if weapon.speed == 1 else "s",
		Weapons.card_text(weapon)]


func _system_name(system: Dictionary) -> String:
	if system.is_empty():
		return "?"
	if system.type == "weapon":
		return system.get("name", "Weapon")
	if system.type == "evb":
		return Catalog.suit_kind(system.suit).name + " Dock"
	return Catalog.systems[system.type].name


func _wrapped(text: String, size: int, color: Color) -> Label:
	var label := UiKit.label(text, size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


## A row: a name that explains itself at the bottom when hovered, then action buttons.
func _row(title: String, detail: String) -> HBoxContainer:
	var row := UiKit.hbox(6)
	var name_label := UiKit.label(title, 14, UiKit.TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.mouse_filter = Control.MOUSE_FILTER_PASS
	name_label.mouse_entered.connect(func(): _explain(title, detail))
	row.add_child(name_label)
	return row


func _add_action(row: HBoxContainer, text: String, action: Callable, why_not: String) -> void:
	var button := UiKit.button(text, func():
		action.call()
		Sounds.play("repair")
		_rebuild(), 13)
	button.disabled = why_not != ""
	button.tooltip_text = why_not
	row.add_child(button)


func _add_buy(box: VBoxContainer, title: String, detail: String, price: float, why_not: String, buy: Callable) -> void:
	var row := _row(title, detail)
	if why_not == "" and not run.can_afford(price):
		why_not = "Not enough Mawjig."
	_add_action(row, "Sold" if why_not == "Sold." else Money.text(price), buy, why_not)
	box.add_child(row)


func _explain(title: String, detail: String) -> void:
	if _info:
		_info.text = title + (": " + detail if detail != "" else "")
