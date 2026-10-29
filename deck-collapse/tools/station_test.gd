## Headless test of the stop between battles: buys everything a station offers, moves weapons and suits through
## cargo, sells, upgrades and undoes, then starts a battle with the changed ship to check it still flies.
## Run: godot --headless --path . res://tools/station_test.tscn
extends Node

const SIMULATE := preload("res://tools/simulate.gd")

var problems: Array[String] = []


func _ready() -> void:
	for design in Catalog.designs.filter(func(d): return d.built_in):
		_check(design)
	print("Station test: %d ships, %d problems" % [Catalog.designs.filter(func(d): return d.built_in).size(), problems.size()])
	for problem in problems:
		print("  ", problem)
	get_tree().quit()


func _check(design: ShipDesign) -> void:
	var enemy: ShipDesign = Catalog.designs[0]
	var run := RunState.new(design)
	run.record_battle(Battle.new(run.design, enemy, 0, 7))
	run.mawjig = 1000.0
	for round in 3:
		run.station = Station.new(run.design, run.rng)
		for section in run.station.sections:
			for item in section.items:
				run.buy(item)
		run.repair_hull(5)
		run.buy_missile()
		for system in run.design.systems.duplicate():
			run.upgrade(system.id)
		run.undo_upgrade()
		for index in range(run.cargo.size() - 1, -1, -1):
			var targets := run.cargo_targets(index)
			if not targets.is_empty():
				run.use_cargo(index, targets[0].target)
		for system in run.weapon_systems():
			run.store_weapon(system.id)
			break
		if not run.cargo.is_empty():
			run.sell_cargo(0)
	if run.design.problems().size() > 0:
		problems.append("%s: %s" % [design.name, ", ".join(run.design.problems())])
	if run.cargo.size() > run.cargo_slots():
		problems.append("%s: cargo over %d" % [design.name, run.cargo_slots()])
	if run.weapon_systems().size() > run.max_weapon_systems():
		problems.append("%s: %d weapon systems" % [design.name, run.weapon_systems().size()])
	print("%-18s systems %2d  weapons %d  cargo %d  crew %d  Mawjig %.2f" % [design.name, run.design.systems.size(),
		run.weapon_systems().size(), run.cargo.size(), run.carry.crew.size(), run.mawjig])
	var battle := Battle.new(run.design, enemy, 0, 9, run.battle_carry())
	var ai := BattleAI.new("Normal", 3)
	var steps := 0
	while not battle.over and steps < 3000:
		var side := battle.active_side
		SIMULATE.perform(battle, side, ai.next_action(battle, side))
		steps += 1
	if not battle.over and not battle.aftermath:
		problems.append("%s: battle after upgrades didn't finish" % design.name)
