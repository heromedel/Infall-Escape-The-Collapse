extends Node
## Runs headless fights and prints how they went. Run: godot --headless --path . tools/test_fight.tscn

func _ready() -> void:
	var wins := 0
	var fights := 20
	var total_ticks := 0
	for index in fights:
		var rng := RandomNumberGenerator.new()
		rng.seed = index
		var run := RunState.new()
		var player := Ship.from_design(Library.ship("outrider"), 0, rng)
		var enemy_id := "pirate-hijacker.cutpurse" if index % 2 == 0 else "light-attack-frame"
		var enemy := Ship.from_design(Library.ship(enemy_id), 1, rng)
		enemy.facing_down = true
		var encounter := Encounter.new()
		encounter.wallet = run
		encounter.setup([player], [enemy], index)
		Formation.lay_out(encounter, "Curve")
		# The player aims everything at the enemy's weapons room with autofire, the simplest captain
		for slot in player.weapons:
			slot.target_ship = enemy
			slot.target_room = enemy.system_by("weapons").room if enemy.system_by("weapons") else 0
			slot.autofire = true
		var ticks := 0
		while encounter.outcome.is_empty() and ticks < 20 * 300:
			encounter.step()
			ticks += 1
			if encounter.notes.size() > 0:
				for note in encounter.notes:
					if index == 0 and note.kind in ["hit", "miss", "shield_hit", "ship_destroyed", "crew_died", "teleported", "surrender_offer", "enemy_escaped", "fight_over", "system_damaged", "fire_started", "breach"]:
						print("  t=%.1f %s %s" % [ticks / 20.0, note.kind, note.get("ship").name if note.get("ship") is Ship else ""])
				encounter.notes.clear()
		total_ticks += ticks
		if encounter.outcome in ["won", "surrendered"]:
			wins += 1
		print("fight %d vs %s: %s after %.1f s; player hull %d/%d, enemy hull %d, crew alive %d/%d, mawjig left %s" % [index, enemy_id, encounter.outcome, ticks / 20.0, player.hull, player.max_hull, enemy.hull, player.living_crew_count(), enemy.living_crew_count(), Mawjig.format(run.mawjig)])
	print("won %d of %d, average %.1f s" % [wins, fights, total_ticks / 20.0 / fights])
	get_tree().quit()
