## Headless test: AI captains fight every pair of built-in ships many times and report results.
## Run: godot --headless --path . res://tools/simulate.tscn  (optional: -- battles=40 level=Normal)
extends Node

const ACTION_LIMIT := 4000


func _ready() -> void:
	var battles_per_pair := 30
	var only := ""
	var ai_level := "Normal"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("battles="):
			battles_per_pair = int(argument.get_slice("=", 1))
		if argument.begins_with("level="):
			ai_level = argument.get_slice("=", 1)
		if argument.begins_with("draw="):
			Settings.values["draw_per_turn"] = argument.get_slice("=", 1)
		if argument.begins_with("only="):
			only = argument.get_slice("=", 1)
	var designs := Catalog.designs.filter(func(d): return d.built_in)
	if only != "":
		designs = designs.filter(func(d): return d.name.to_lower().contains(only) or d.name == "SC-1 Outrider")
	var wins := {}
	var turn_totals := 0
	var battle_count := 0
	var outcomes := {}
	var stalls := 0
	var purse_dry := [0, 0]
	var purse_left := [0.0, 0.0]
	print("Ships: ", designs.map(func(d): return "%s (%.0f M)" % [d.name, d.total_cost()]))
	for a in designs:
		for b in designs:
			if a == b:
				continue
			var pair_wins := [0, 0, 0]
			for i in battles_per_pair:
				var seed_value := 1000 + i * 7919 + battle_count
				var battle := Battle.new(a, b, i % 2, seed_value)
				var captains := [BattleAI.new(ai_level, seed_value + 1), BattleAI.new(ai_level, seed_value + 2)]
				var actions := 0
				while not battle.over and not battle.aftermath and actions < ACTION_LIMIT:
					var side := battle.active_side
					var action: Dictionary = captains[side].next_action(battle, side)
					var events := perform(battle, side, action)
					if events.any(func(e): return e.type == "refused"):
						print("REFUSED ", action, " ", events.filter(func(e): return e.type == "refused"))
						battle.end_turn(side)
					actions += 1
				if not battle.over and not battle.aftermath:
					stalls += 1
					pair_wins[2] += 1
				elif battle.winner >= 0 and battle.outcome != Battle.OUTCOME_ESCAPED:
					pair_wins[battle.winner] += 1
				else:
					pair_wins[2] += 1
				outcomes[battle.outcome] = outcomes.get(battle.outcome, 0) + 1
				for side in 2:
					purse_left[side] += battle.ships[side].mawjig
					if battle.ships[side].mawjig < 0.05:
						purse_dry[side] += 1
				turn_totals += battle.turn_number
				battle_count += 1
				var decisive := battle.outcome != Battle.OUTCOME_ESCAPED
				wins[a.name] = wins.get(a.name, 0) + (1 if decisive and battle.winner == 0 else 0)
				wins[b.name] = wins.get(b.name, 0) + (1 if decisive and battle.winner == 1 else 0)
			print("%-22s vs %-22s  %2d - %2d  (other %d)" % [a.name, b.name, pair_wins[0], pair_wins[1], pair_wins[2]])
	print("Average captain turns per battle: %.1f" % (float(turn_totals) / battle_count))
	print("Outcomes: ", outcomes, "  stalls: ", stalls)
	print("Mawjig left on average: side 0 %.2f, side 1 %.2f; battles ending with a purse under 0.05: %s" % [
		purse_left[0] / battle_count, purse_left[1] / battle_count, purse_dry])
	for ship_name in wins:
		print("  %-22s wins %d" % [ship_name, wins[ship_name]])
	get_tree().quit()


static func perform(battle: Battle, side: int, action: Dictionary) -> Array:
	match action.kind:
		"play": return battle.play_card(side, action.uid, action.target)
		"move": return battle.move_crew(side, action.crew, action.system)
		"burn": return battle.burn_engines(side)
		"reroute": return battle.reroute_power(side)
		"jump": return battle.jump(side)
	return battle.end_turn(side)
