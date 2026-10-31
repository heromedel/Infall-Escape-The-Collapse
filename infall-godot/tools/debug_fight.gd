extends Node

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	var player := Ship.from_design(Library.ship(OS.get_environment("P") if OS.get_environment("P") != "" else "outrider"), 0, rng)
	var enemy := Ship.from_design(Library.ship(OS.get_environment("E")), 1, rng)
	enemy.facing_down = true
	var encounter := Encounter.new()
	encounter.wallet = RunState.new()
	encounter.setup([player], [enemy], 1)
	Formation.lay_out(encounter, "Curve")
	for slot in player.weapons:
		slot.target_ship = enemy
		slot.target_room = 0
		slot.autofire = true
	for t in 20 * 60:
		encounter.step()
		encounter.notes.clear()
		if t % 40 == 0:
			var s := "t=%d " % (t / 20)
			for sys in enemy.systems:
				s += "%s:%d/%d(d%d,m%s) " % [sys.def.id, enemy.system_power(sys), sys.level, sys.damage, "Y" if sys.manned_by else "n"]
			for w in enemy.weapons:
				s += " W[%s p=%s c=%.0f/%.0f tgt=%s]" % [w.def.id, w.powered, w.charge, w.charge_needed(enemy.tech), w.has_target()]
			for c in enemy.crew:
				s += " C[%s %s cell=%s task=%s hp=%d]" % [c.name, c.ship.name, c.cell, c.task, c.health]
			print(s, " shields=", enemy.shield_layers, " P.hull=", player.hull, " P.shields=", player.shield_layers, " E.hull=", enemy.hull)
		if not encounter.outcome.is_empty():
			print("outcome ", encounter.outcome, " at ", t / 20.0)
			break
	get_tree().quit()
