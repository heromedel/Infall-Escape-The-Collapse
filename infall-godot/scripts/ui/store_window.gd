class_name StoreWindow
extends Overlay
## A cluster's store: weapons, systems, crew, sometimes a ship, hull repairs, and selling what the squad
## carries. Stock depends on the cluster's race and state (GDD 2R: doomed and refugee stores run short); prices
## come from the reference tables. Mawjig can't be bought here: it is the money. Purchases are orders (Refit), so
## every player sees the same store; the window shows again whenever the run changes.

var run: RunState
var ship: Ship
var give: Callable                    # sends a refit order to the stream
var _content: VBoxContainer          # the scrolling area: a long store scrolls instead of running off the screen
var _money := Label.new()


func open(run_state: RunState, for_ship: Ship) -> void:
	run = run_state
	ship = for_ship
	place_panel(1240, 0)
	var top := HBoxContainer.new()
	top.add_child(UiKit.title_label("STORE · %s" % run.cluster().name.to_upper(), 30))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	_money.add_theme_font_override("font", UiKit.font_title())
	_money.add_theme_font_size_override("font_size", 28)
	_money.add_theme_color_override("font_color", Color("#ffd46b"))
	top.add_child(_money)
	body.add_child(top)
	_content = scrolling_area()
	add_button("LEAVE THE STORE", close)
	Refit.ensure_stock(run)
	_rebuild()


func _price_scale() -> float:
	var states: Array = run.cluster().states
	if states.has("Doomed"):
		return 1.3
	if states.has("Struggling") or states.has("Occupied"):
		return 1.12
	return 1.0


func _rebuild() -> void:
	if not is_instance_valid(ship) or ship.is_gone() or not run.squad.has(ship):
		ship = run.living_ships()[0] if not run.living_ships().is_empty() else null
	if ship == null:
		close()
		return
	clear(_content)
	_money.text = "MAWJIG  " + Mawjig.format(run.mawjig)
	var stock: Dictionary = run.cluster().store_stock
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	_content.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(590, 0)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(590, 0)
	columns.add_child(left)
	columns.add_child(right)
	left.add_child(_section("WEAPONS"))
	for weapon_id in stock.weapons:
		var def := Library.weapon(weapon_id)
		if def == null:
			continue
		var price := Mawjig.amount(def.price * _price_scale() / 100.0)
		var sold: bool = stock.sold.has("weapon:" + weapon_id)
		left.add_child(_card(def.display_name(), "%s\n%s · charge %.1f s · power %d" % [def.description, def.stat_line(), def.charge_seconds(), def.power], price, sold, func(): _buy_weapon(def, price)))
	left.add_child(_section("CREW"))
	for index in stock.crew.size():
		var race := Library.race(stock.crew[index])
		var price := Mawjig.amount(race.crew_price * _price_scale() / 100.0)
		var sold: bool = stock.sold.has("crew:%d" % index)
		left.add_child(_card("%s crew member" % race.name, race.traits_text, price, sold, func(): _buy_crew(race, index, price)))
	right.add_child(_section("SYSTEMS"))
	for system_id in stock.systems:
		var def := Library.system(system_id)
		if def == null:
			continue
		var price := Mawjig.amount(def.buy_price * _price_scale() / 100.0)
		var owned := ship.system_by_id(system_id) != null
		var sold: bool = stock.sold.has("system:" + system_id) or owned
		right.add_child(_card(def.name, def.description + ("\nAlready installed on the %s." % ship.name if owned else ""), price, sold, func(): _buy_system(def, price)))
	if stock.ship != "" and not stock.sold.has("ship"):
		var design := Library.ship(stock.ship)
		if design:
			var price := Mawjig.amount(design.value * 1.15 * _price_scale() / 100.0)
			var full := run.living_ships().size() >= EventRunner.MAX_SQUAD
			right.add_child(_section("SHIPYARD"))
			right.add_child(_card(design.name, "%s\nHull %d, crew %d. Joins your squad with its crew." % [design.description, design.hull, design.crew.size()], price, full, func(): _buy_ship(design, price)))
	right.add_child(_section("REPAIRS"))
	var per_point := Refit.repair_price(run)
	var damaged := 0
	for each in run.living_ships():
		damaged += each.max_hull - each.hull
	var repair_row := HBoxContainer.new()
	repair_row.add_theme_constant_override("separation", 8)
	repair_row.add_child(UiKit.label("Hull %d missing across the squad · %s a point" % [damaged, Mawjig.format(per_point)], 17, UiColours.TEXT_DIM))
	right.add_child(repair_row)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	var one := UiKit.button("REPAIR 1", func(): _repair(1), 140)
	one.disabled = damaged == 0 or run.mawjig < per_point
	buttons.add_child(one)
	var five := UiKit.button("REPAIR 5", func(): _repair(5), 140)
	five.disabled = damaged == 0 or run.mawjig < per_point
	buttons.add_child(five)
	var all_cost := Mawjig.no_trailing_zero(per_point * damaged)
	var all_button := UiKit.button("REPAIR ALL (%s)" % Mawjig.format(all_cost), func(): _repair(damaged), 230)
	all_button.disabled = damaged == 0 or run.mawjig < per_point
	buttons.add_child(all_button)
	right.add_child(buttons)
	if not run.cargo.is_empty():
		right.add_child(_section("SELL FROM THE HOLD"))
		for index in run.cargo.size():
			var def := Library.weapon(run.cargo[index])
			if def == null:
				continue
			var price := Mawjig.no_trailing_zero(def.price / 2)
			var row := HBoxContainer.new()
			row.add_child(UiKit.label(def.display_name(), 17))
			var spacer := Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(spacer)
			row.add_child(UiKit.button("SELL +%s" % Mawjig.format(price), func(): _sell(index, price), 160))
			right.add_child(row)


func _section(text: String) -> Label:
	var label := UiKit.label(text, 16, UiColours.ACCENT, true)
	label.custom_minimum_size = Vector2(0, 30)
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	return label


func _card(title: String, detail: String, price: int, sold: bool, on_buy: Callable) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.box(UiColours.PANEL_LIGHT if not sold else UiColours.PANEL_DARK, UiColours.BORDER_DIM, 1, 4, 10))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(UiKit.label(title, 18, UiColours.TEXT if not sold else UiColours.TEXT_DIM, true))
	var detail_label := UiKit.label(detail, 14, UiColours.TEXT_DIM)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.custom_minimum_size = Vector2(400, 0)
	text.add_child(detail_label)
	row.add_child(text)
	var buy := UiKit.button("SOLD" if sold else Mawjig.format(price), func(): LowMawjigWarning.confirm(self, run, price, on_buy), 110)
	buy.disabled = sold or run.mawjig < price
	buy.add_theme_color_override("font_color", Color("#ffd46b"))
	row.add_child(buy)
	return card


func _order(fields: Dictionary) -> void:
	fields["k"] = "refit"
	fields["sq"] = run.squad.find(ship)
	give.call(fields)


func _repair(points: int) -> void:
	_order({"op": "repair", "points": points})
	Sfx.play("repair")


func _buy_weapon(def: WeaponDef, price: int) -> void:
	_order({"op": "buy_weapon", "id": def.id, "price": price})
	Sfx.play("buy")


func _buy_crew(race: RaceDef, index: int, price: int) -> void:
	_order({"op": "buy_crew", "race": race.id, "index": index, "price": price})
	Sfx.play("buy")


func _buy_system(def: SystemDef, price: int) -> void:
	if ShipOutfitter.room_for_new_system(ship) < 0 or run.mawjig < price:
		Sfx.play("deny")
		return
	var picker := RoomPicker.new()
	get_parent().add_child(picker)
	picker.open(ship, def.name)
	picker.picked.connect(func(room: int):
		_order({"op": "buy_system", "id": def.id, "price": price, "room": room})
		Sfx.play("buy"))


func _buy_ship(design: ShipDesign, price: int) -> void:
	_order({"op": "buy_ship", "id": design.id, "price": price})
	Sfx.play("buy")


func _sell(index: int, price: int) -> void:
	_order({"op": "sell", "index": index, "id": run.cargo[index], "price": price})
	Sfx.play("buy")
