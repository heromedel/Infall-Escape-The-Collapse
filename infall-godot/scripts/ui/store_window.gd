class_name StoreWindow
extends Overlay
## A cluster's store: weapons, systems, crew, sometimes a ship, hull repairs, and selling what the squad
## carries. Stock depends on the cluster's race and state (GDD 2R: doomed and refugee stores run short); prices
## come from the reference tables. Mawjig can't be bought here: it is the money.

const INSTALLABLE := ["medbay", "doors", "sensors", "crew-teleporter", "cloaking", "supershield", "evb-dock", "shields", "life-support"]

var run: RunState
var ship: Ship
var _content := VBoxContainer.new()
var _scroll := ScrollContainer.new()   # a long store scrolls instead of running off the screen
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
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.add_child(_content)
	body.add_child(_scroll)
	add_button("LEAVE THE STORE", close)
	_ensure_stock()
	_rebuild()


func _price_scale() -> float:
	var states: Array = run.cluster().states
	if states.has("Doomed"):
		return 1.3
	if states.has("Struggling") or states.has("Occupied"):
		return 1.12
	return 1.0


func _ensure_stock() -> void:
	var cluster := run.cluster()
	if not cluster.store_stock.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(cluster.seed) + 77
	var race: String = cluster.race if cluster.race != "" else "terran"
	var short: bool = cluster.states.has("Doomed") or cluster.states.has("Refugee") or cluster.states.has("Occupied")
	var stock := {"weapons": [], "systems": [], "crew": [], "ship": "", "sold": []}
	var weapon_pool: Array = []
	for def in Library.weapons.values():
		if def.type == "suit" or def.id.ends_with("-stolen"):
			continue
		var weight := 3 if def.race == race else 1
		if def.price > 1200 + run.band() * 280:
			continue
		for copy in weight:
			weapon_pool.append(def.id)
	for count in (2 if short else 3):
		if weapon_pool.is_empty():
			break
		var pick: String = weapon_pool[rng.randi_range(0, weapon_pool.size() - 1)]
		weapon_pool = weapon_pool.filter(func(id): return id != pick)
		stock.weapons.append(pick)
	var systems := INSTALLABLE.duplicate()
	if race != "tentauri":
		systems.erase("supershield")
	if race != "mecha":
		systems.erase("evb-dock")
	if race != "lykario":
		systems.erase("cloaking")
	systems.shuffle()
	for index in mini(2 if short else 3, systems.size()):
		stock.systems.append(systems[index])
	var crew_races := [race, "terran"] if race != "malphen" else ["terran"]
	for count in (1 if short else 2):
		stock.crew.append(crew_races[rng.randi_range(0, crew_races.size() - 1)])
	if (cluster.race == "terran" and cluster.rank != "border" and rng.randf() < 0.45) or (cluster.states.has("Refugee") and rng.randf() < 0.5):
		var ships := {"terran": ["patrol-cutter", "outrider"], "tentauri": ["tentauri-scout"], "azurethea": ["moth-skiff"], "lykario": ["packrunner"], "senti": ["relay-picket"], "mecha": ["light-attack-frame"]}.get(race, ["patrol-cutter"]) as Array
		stock.ship = ships[rng.randi_range(0, ships.size() - 1)]
	cluster.store_stock = stock


func _rebuild() -> void:
	for child in _content.get_children():
		_content.remove_child(child)   # out of the layout now, not at the end of the frame
		child.queue_free()
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
	var per_point := _repair_price()
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
	_fit_to_screen.call_deferred()


## Shrinks the window back around its contents after a rebuild, scrolling when the store is taller than the screen.
func _fit_to_screen() -> void:
	var most := get_viewport_rect().size.y - 260.0
	_scroll.custom_minimum_size = Vector2(0, minf(_content.get_combined_minimum_size().y, most))
	panel.size = Vector2.ZERO
	_recentre()


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
	var buy := UiKit.button("SOLD" if sold else Mawjig.format(price), on_buy, 110)
	buy.disabled = sold or run.mawjig < price
	buy.add_theme_color_override("font_color", Color("#ffd46b"))
	row.add_child(buy)
	return card


func _repair_price() -> int:
	# Per hull point by band: 0.48 in bands 1-3, 0.73 in 4-6, 0.97 in 7-8 (mawjig-cost-table.md)
	var band := run.band()
	return 48 if band <= 3 else (73 if band <= 6 else 97)


func _repair(points: int) -> void:
	var per_point := _repair_price()
	for count in points:
		var target: Ship = null
		for each in run.living_ships():
			if each.hull < each.max_hull and (target == null or float(each.hull) / each.max_hull < float(target.hull) / target.max_hull):
				target = each
		if target == null or not run.spend(per_point):
			break
		target.repair_hull(1)
	Sfx.play("repair")
	_rebuild()


func _buy_weapon(def: WeaponDef, price: int) -> void:
	if not run.spend(price):
		return
	run.cluster().store_stock.sold.append("weapon:" + def.id)
	var fitted := ShipOutfitter.fit_weapon(ship, def)
	if not fitted:
		run.cargo.append(def.id)
	run.log_book.write("bought", {"weapon": def.id, "price": price}, "Bought %s for %s." % [def.display_name(), Mawjig.format(price)])
	Sfx.play("buy")
	_rebuild()


func _buy_crew(race: RaceDef, index: int, price: int) -> void:
	var target: Ship = null
	for each in [ship] + run.living_ships():
		if each.living_crew_count() < EventRunner.MAX_CREW_PER_SHIP:
			target = each
			break
	if target == null:
		return
	if not run.spend(price):
		return
	run.cluster().store_stock.sold.append("crew:%d" % index)
	var member := CrewMember.create(race, race.random_name(run.rng, target.crew.map(func(c): return c.name)))
	target.add_crew(member)
	target.assign_stations()
	run.log_book.write("hired", {"race": race.id, "name": member.name}, "%s joined the %s." % [member.name, target.name])
	Sfx.play("buy")
	_rebuild()


func _buy_system(def: SystemDef, price: int) -> void:
	if ShipOutfitter.room_for_new_system(ship) < 0 or run.mawjig < price:
		Sfx.play("deny")
		return
	var picker := RoomPicker.new()
	get_parent().add_child(picker)
	picker.open(ship, def.name)
	picker.picked.connect(func(room: int): _install(def, price, room))


func _install(def: SystemDef, price: int, room: int) -> void:
	if not run.spend(price):
		return
	ShipOutfitter.install_system(ship, def, room)
	run.cluster().store_stock.sold.append("system:" + def.id)
	run.log_book.write("installed", {"system": def.id, "room": room}, "Installed %s on the %s." % [def.name, ship.name])
	Sfx.play("buy")
	_rebuild()


func _buy_ship(design: ShipDesign, price: int) -> void:
	if not run.spend(price):
		return
	var bought := Ship.from_design(design, 0, run.rng, Settings.get_value("terran_conduits", true))
	run.squad.append(bought)
	run.cluster().store_stock.sold.append("ship")
	run.log_book.write("bought_ship", {"design": design.id, "price": price}, "The %s joined the squad." % bought.name)
	Sfx.play("buy")
	_rebuild()


func _sell(index: int, price: int) -> void:
	if index >= run.cargo.size():
		return
	run.cargo.remove_at(index)
	run.earn(price)
	Sfx.play("buy")
	_rebuild()
