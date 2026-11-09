extends Node
## Checks mercenary contracts (GV 7C): hiring, counting jumps, renewing at a rising price, leaving with their own
## crew after losses, saving and loading, and that mercenaries alone don't keep a run alive.
## Run: godot --headless --path . tools/mercenary_test.tscn

var failures := 0


func _ready() -> void:
	var run := RunState.start(4242, "outrider")
	run.mawjig = 5000
	var runner := EventRunner.new(run)
	var hire: Dictionary = Library.events["NEUTRAL_MERCENARY"].choices[0]
	runner.resolve(hire, "")
	_check(run.squad.size() == 2, "hiring adds the ship")
	var merc: Ship = run.squad[1]
	_check(merc.is_mercenary() and int(merc.contract.jumps_left) == 3, "the contract runs 3 jumps")
	_check(merc.crew.all(func(m): return m.contract_id == int(merc.contract.id)), "its crew are on the contract")
	_check(run.own_ships().size() == 1, "a mercenary is not one of the squad's own ships")
	for index in 3:
		run.jump_to(run.cluster().links[0])
	_check(run.contracts_due() == [merc], "the contract is due after 3 jumps")
	var before := run.mawjig
	runner.mercenary = merc
	_check(runner.requirement_label({"requires": "renewal"}) == "(12.08 Mawjig)", "renewal costs a quarter more: %s" % runner.requirement_label({"requires": "renewal"}))
	runner.resolve(Library.events["MERCENARY_CONTRACT_UP"].choices[0], "")
	_check(before - run.mawjig == 1208 and int(merc.contract.jumps_left) == 3, "renewing pays and resets the term")
	_check(run.renewal_price(merc) == 1510, "the next renewal costs more again: %d" % run.renewal_price(merc))
	# One of ours aboard the mercenary ship, one mercenary aboard ours
	var ours := run.squad[0].crew[0]
	run.squad[0].crew.erase(ours)
	merc.add_crew(ours)
	var hired: CrewMember = merc.crew[0]
	merc.crew.erase(hired)
	run.squad[0].add_crew(hired)
	run.count_mercenary_crew()
	merc.crew[1].dead = true
	_check(run.mercenaries_with_losses() == [merc], "a dead mercenary counts as a loss")
	# Saving and loading keeps the contract
	var saved := Ship.from_save(merc.to_save(), 0)
	_check(int(saved.contract.id) == int(merc.contract.id) and saved.crew.any(func(m): return m.contract_id == int(merc.contract.id)), "the contract survives a save")
	runner.resolve(Library.events["MERCENARY_WALKOUT"].choices[1], "")
	_check(run.squad.size() == 1, "letting them go removes the ship")
	_check(run.squad[0].crew.has(ours), "our crew member comes back aboard")
	_check(not run.squad[0].crew.has(hired), "their crew member leaves with them")
	runner.mercenary = null
	# Mercenaries alone don't keep the run alive
	runner.resolve(hire, "")
	var encounter := Encounter.new()
	encounter.setup(run.living_ships(), [Ship.from_design(Library.ship("pirate-scrapper"), 1, run.rng)], 1)
	run.squad[0].destroyed = true
	encounter.step()
	_check(encounter.outcome == "lost", "the fight is lost when only mercenaries are left")
	print("PASS" if failures == 0 else "FAIL: %d" % failures)
	get_tree().quit()


func _check(ok: bool, what: String) -> void:
	print("%s  %s" % ["ok  " if ok else "FAIL", what])
	if not ok:
		failures += 1
