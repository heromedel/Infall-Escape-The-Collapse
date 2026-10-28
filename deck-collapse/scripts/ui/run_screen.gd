## Between battles in a run: what the last battle paid, the ship's state, and a stop to spend Mawjig on hull repair,
## missiles and crew before jumping to the next battle against a random enemy.
class_name RunScreen
extends Control

signal next_battle
signal end_run

const HIRE_NAMES := ["Ada", "Bram", "Cass", "Dov", "Esme", "Finn", "Gale", "Hux", "Ines", "Jory", "Kael", "Lio",
	"Mira", "Nox", "Orla", "Pike", "Quin", "Rhea", "Sol", "Tamsin"]

var run: RunState
var _body: VBoxContainer


func _ready() -> void:
	add_child(Starfield.new())
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiKit.panel(Color(0.06, 0.08, 0.13, 0.95))
	panel.custom_minimum_size = Vector2(900, 0)
	center.add_child(panel)
	_body = UiKit.vbox(14)
	panel.add_child(UiKit.margin(_body, 16))
	_rebuild()


func _rebuild() -> void:
	for child in _body.get_children():
		child.queue_free()
	var color := Color.from_string(run.design.color, UiKit.GOOD)
	var top := UiKit.hbox(12)
	var title := UiKit.heading("BETWEEN BATTLES", 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	top.add_child(UiKit.heading(Money.text(run.mawjig), 30, UiKit.ACCENT))
	_body.add_child(top)

	var result: Dictionary = run.last_result
	var summary := "Battle %d against %s: " % [run.battles_fought, result.get("enemy", "?")]
	match result.get("outcome", ""):
		Battle.OUTCOME_DESTROYED: summary += "destroyed it."
		Battle.OUTCOME_CREW_LOST: summary += "killed its crew."
		_: summary += "no salvage."
	_body.add_child(UiKit.label(summary, 17, UiKit.TEXT))
	_body.add_child(UiKit.label("Salvage +%s   ·   Jump -%s   ·   Battles won: %d" % [Money.text(result.get("reward", 0.0)),
		Money.text(result.get("jump_cost", 0.0)), run.battles_won], 15, UiKit.MUTED))

	# The ship as it is.
	var ship_panel := UiKit.panel(UiKit.PANEL_LIGHT, color.darkened(0.4), 8)
	var ship_box := UiKit.vbox(6)
	ship_panel.add_child(ship_box)
	ship_box.add_child(UiKit.heading(run.design.name.to_upper(), 22, color))
	var status := "Hull %d / %d" % [run.hull(), run.hull_max()]
	if run.uses_missiles():
		status += "   ·   %d missiles" % int(run.carry.get("missiles", 0))
	ship_box.add_child(UiKit.label(status, 16, UiKit.TEXT, UiKit.body_bold_font))
	var damaged: Array[String] = []
	for system_id in run.carry.get("systems", {}):
		var saved: Dictionary = run.carry.systems[system_id]
		var system := run.design.system_by_id(system_id)
		var system_name: String = system.get("name", Catalog.systems[system.type].name) if system.type == "weapon" else Catalog.systems[system.type].name
		var notes: Array[String] = []
		if saved.damage > 0:
			notes.append("%d damaged" % saved.damage)
		if saved.on_fire:
			notes.append("on fire")
		if saved.breached:
			notes.append("breached")
		if not notes.is_empty():
			damaged.append("%s (%s)" % [system_name, ", ".join(notes)])
	var systems_line := UiKit.label("Systems: " + (", ".join(damaged) if not damaged.is_empty() else "all working"), 14,
		UiKit.DANGER if not damaged.is_empty() else UiKit.MUTED)
	systems_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ship_box.add_child(systems_line)
	var crew_names: Array = run.carry.get("crew", []).map(func(m): return "%s (%d/%d)" % [m.name, Battle.WOUNDS_TO_DIE - int(m.wounds), Battle.WOUNDS_TO_DIE])
	var crew_line := UiKit.label("Crew: " + ", ".join(crew_names), 14, UiKit.MUTED)
	crew_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ship_box.add_child(crew_line)
	ship_box.add_child(UiKit.label("System damage, fires and wounds carry into the next battle; fix them there, after you win.", 13, UiKit.FAINT))
	_body.add_child(ship_panel)

	# The stop.
	_body.add_child(UiKit.heading("STOP", 20, UiKit.ACCENT))
	var shop := GridContainer.new()
	shop.columns = 2
	shop.add_theme_constant_override("h_separation", 10)
	shop.add_theme_constant_override("v_separation", 8)
	var missing := run.hull_max() - run.hull()
	_add_purchase(shop, "Repair 1 hull", run.hull_repair_price(), missing > 0, func(): run.repair_hull(1))
	_add_purchase(shop, "Repair all hull (%d)" % missing, run.hull_repair_price() * missing, missing > 0,
		func(): run.repair_hull(missing))
	if run.uses_missiles():
		_add_purchase(shop, "Buy 1 missile", run.missile_price(), true, func(): run.buy_missile())
	_add_purchase(shop, "Hire a crew member", run.crew_price(), run.carry.get("crew", []).size() < 8,
		func(): run.hire_crew(HIRE_NAMES[randi() % HIRE_NAMES.size()]))
	_body.add_child(shop)

	var buttons := UiKit.hbox(12)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	var go := UiKit.primary_button("NEXT BATTLE (random enemy)", func(): next_battle.emit(), 20)
	go.custom_minimum_size.y = 50
	buttons.add_child(go)
	buttons.add_child(UiKit.button("End Run", func(): end_run.emit(), 18))
	_body.add_child(buttons)


func _add_purchase(grid: GridContainer, text: String, price: float, available: bool, buy: Callable) -> void:
	var button := UiKit.button("%s  —  %s" % [text, Money.text(price)], func():
		buy.call()
		Sounds.play("repair")
		_rebuild(), 16)
	button.disabled = not available or not run.can_afford(price)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(button)
