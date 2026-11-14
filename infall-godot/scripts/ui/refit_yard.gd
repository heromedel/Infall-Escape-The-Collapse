class_name RefitYard
extends Overlay
## A store's refit yard (GV 5E; heromedel, 2026-11-14): move a system from one of the squad's ships to another for a
## quarter of its value, or sell a ship. The store opens it and rebuilds it when the run changes.

var run: RunState
var give: Callable                    # sends a refit order to the stream
var _content: VBoxContainer


func open(run_state: RunState, give_order: Callable) -> void:
	run = run_state
	give = give_order
	place_panel(1040, 0)
	add_title("REFIT YARD")
	add_text("Move a system from one of your ships to another, for a quarter of its value. It goes into a room of your choice: a Medbay needs a room without manned systems, and an EVA or EVB Dock needs an airlock.", 17, UiColours.TEXT_DIM)
	_content = scrolling_area()
	add_button("BACK TO THE STORE", close)
	rebuild()


func rebuild() -> void:
	if _content == null:
		return
	clear(_content)
	for ship in run.own_ships():
		var head := HBoxContainer.new()
		head.add_child(UiKit.label(ship.name.to_upper(), 18, UiColours.ACCENT, true))
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(spacer)
		var why_not := Refit.sell_ship_refusal(run, ship)
		var sell := UiKit.button("SELL THE SHIP  +" + Mawjig.format(Refit.sell_ship_price(run, ship)), func(): _confirm_sale(ship), 250)
		sell.disabled = not why_not.is_empty()
		sell.tooltip_text = why_not
		head.add_child(sell)
		_content.add_child(head)
		for system in ship.systems:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			var level: int = ship.reactor_level if system.behaviour == "power_core" else system.level
			var name := UiKit.label("%s  ·  %s %d" % [system.def.name + (" " + system.label if system.label != "" else ""), "power" if system.behaviour == "power_core" else "level", level], 16)
			name.custom_minimum_size = Vector2(430, 0)
			row.add_child(name)
			var targets: Array[Ship] = run.own_ships().filter(func(other: Ship): return Refit.move_refusal_between(run, ship, system, other).is_empty())
			var price := Refit.move_price(ship, system)
			var move := UiKit.button("MOVE  " + Mawjig.format(price), func(): _choose_ship(ship, system), 150)
			move.disabled = targets.is_empty()
			if targets.is_empty():
				var reasons: PackedStringArray = []
				for other in run.own_ships():
					if other != ship:
						reasons.append(Refit.move_refusal_between(run, ship, system, other))
				move.tooltip_text = "\n".join(reasons) if not reasons.is_empty() else "There is no other ship to move it to."
			row.add_child(move)
			_content.add_child(row)
		_content.add_child(HSeparator.new())


func _choose_ship(from: Ship, system: ShipSystem) -> void:
	var window := Overlay.new()
	get_parent().add_child(window)
	window.place_panel(640)
	window.add_title("MOVE THE %s" % system.def.name.to_upper())
	window.add_text("From the %s, for %s Mawjig. To which ship?" % [from.name, Mawjig.format(Refit.move_price(from, system))], 18, UiColours.TEXT_DIM)
	for other in run.own_ships():
		if other == from:
			continue
		var why := Refit.move_refusal_between(run, from, system, other)
		var button := window.add_button("To the %s." % other.name if why.is_empty() else "%s: %s" % [other.name, why], func():
			window.close()
			_choose_room(from, system, other))
		button.disabled = not why.is_empty()
	window.add_button("Cancel", window.close)


func _choose_room(from: Ship, system: ShipSystem, to: Ship) -> void:
	var picker := RoomPicker.new()
	get_parent().add_child(picker)
	picker.open(to, system.def)
	picker.picked.connect(func(room: int): _confirm_move(from, system, to, room))


func _confirm_move(from: Ship, system: ShipSystem, to: Ship, room: int) -> void:
	var warning := Refit.move_warning(from, system)
	if warning.is_empty():
		_send_move(from, system, to, room)
		return
	var window := Overlay.new()
	get_parent().add_child(window)
	window.place_panel(680)
	window.add_title("WARNING", UiColours.WARNING)
	window.add_text(warning, 20)
	window.add_button("1. Move it anyway.", func():
		window.close()
		_send_move(from, system, to, room), UiColours.DAMAGED_RED)
	window.add_button("2. Leave it where it is.", window.close)


func _send_move(from: Ship, system: ShipSystem, to: Ship, room: int) -> void:
	give.call({"k": "refit", "op": "move_system", "sq": run.squad.find(from), "sys": from.systems.find(system), "to": run.squad.find(to), "room": room})
	Sfx.play("buy")


func _confirm_sale(ship: Ship) -> void:
	var room := 0
	for other in run.own_ships():
		if other != ship:
			room += maxi(0, EventRunner.MAX_CREW_PER_SHIP - other.living_crew_count())
	var crew := ship.living_crew_count()
	var window := Overlay.new()
	get_parent().add_child(window)
	window.place_panel(680)
	window.add_title("SELL THE %s?" % ship.name.to_upper(), UiColours.WARNING)
	window.add_text("The yard pays %s Mawjig. Its crew will move to your other ships where there's room. Anyone without a bunk leaves with it.%s" % [Mawjig.format(Refit.sell_ship_price(run, ship)), "" if room >= crew else " Your other ships have room for %d of its crew of %d." % [room, crew]], 20)     # Infall: Lori
	window.add_button("1. Sell it.", func():
		window.close()
		give.call({"k": "refit", "op": "sell_ship", "sq": run.squad.find(ship)})
		Sfx.play("buy"), UiColours.DAMAGED_RED)
	window.add_button("2. Keep it.", window.close)
