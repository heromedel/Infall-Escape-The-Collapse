class_name HailWindow
extends Overlay
## The Hail button (GDD 3O): ask for or offer surrender, or offer terms. What an enemy accepts follows its
## squad's conduct and race (race profiles: the Mecha take a surrender only if they profit; the Tentauri just
## want past; the Malphen can be paid in matter; the Azurethea readily accept).

signal decided(outcome: String, mawjig: int)

var run: RunState
var encounter: Encounter
var squad: SquadDef


func open(run_state: RunState, current: Encounter, enemy_squad: SquadDef) -> void:
	run = run_state
	encounter = current
	squad = enemy_squad
	place_panel(760)
	var hail := squad.hail if squad else "hostile"
	add_title("HAIL · %s" % (squad.name.to_upper() if squad else "ENEMY"))
	add_text(_greeting(hail), 20)
	add_separator()
	var toll := Mawjig.amount(1.81 * run.band_adjustment() * maxf(1.0, encounter.living(1).size()))
	add_button("1. Demand their surrender.", func(): _demand(hail))
	if hail not in ["rival", "malphen"]:
		add_button("2. Tell them you only want to pass through.", func(): _ask_passage(hail))
	if hail != "rival":
		var offer := add_button("3. Offer %s Mawjig to be left alone." % Mawjig.format(toll), func(): _offer(hail, toll))
		offer.disabled = run.mawjig < toll
	add_button("4. Close the channel.", func(): decided.emit("", 0); close())


func _greeting(hail: String) -> String:
	match hail:
		"pirate":
			return "A rough voice answers, ship to ship. \"Power down your weapons and nobody has to breathe vacuum. We just want the ship.\""
		"checkpoint":
			return "\"This is a GATOS checkpoint. Everyone pays now. Everyone. You know why.\""
		"mecha":
			return "The channel opens on a dark visor lit purple. \"You are in our territory. Tell us why we shouldn't take what you have.\""
		"tentauri":
			return "Two soft voices answer at once, polite and immovable. \"We are going through. We would rather you were not in the way.\""
		"azurethea":
			return "\"We don't want this,\" the Azurethea captain says. \"Stand down and we will too.\""
		"senti":
			return "\"We, The Senti-, are listening. State your terms.\""
		"lykario":
			return "Laughter and howling come over the channel. \"Good hunting! Why stop now?\""
		"malphen":
			return "There is no answer. Only static, and something on the channel that sounds like breathing."
		"rival":
			return "\"We know where you're going,\" the fleet's leader says. \"There's only room for one of us out there.\""
	return "The enemy answers your hail."


func _enemy_strength() -> float:
	var total := 0.0
	var count := 0
	for ship in encounter.living(1):
		total += float(ship.hull) / ship.max_hull
		count += 1
	return total / maxf(1, count)


func _demand(hail: String) -> void:
	var chance := (squad.surrender_chance if squad else 20) * (1.6 - _enemy_strength())
	if hail == "rival" or hail == "malphen":
		chance = 0
	if run.rng.randf() * 100.0 < chance:
		_result("They power down their weapons. \"Fine. Take this and let us go.\"", "surrendered", 0)
	else:
		_result("They laugh at you and keep firing." if hail != "malphen" else "Nothing answers. The living ship keeps coming.", "", 0)


func _ask_passage(hail: String) -> void:
	if hail in ["tentauri", "azurethea"] or (hail == "mecha" and _enemy_strength() < 0.6):
		var text := "\"Then go,\" they answer, and their weapons fall quiet. They let your squad pass." if hail != "mecha" else "\"Get out of our territory, then.\" Their guns stay hot, but they hold fire."
		_result(text, "passage", 0)
	else:
		_result("\"Nobody passes for free,\" comes the answer.", "", 0)


func _offer(hail: String, toll: int) -> void:
	var accepts := hail in ["pirate", "checkpoint", "mecha", "malphen", "lykario", "senti"] and run.rng.randf() < (0.85 if hail != "lykario" else 0.45)
	if accepts and run.spend(toll):
		var text := "They take the Mawjig and break off." if hail != "malphen" else "A tendril of the living ship takes the matter you jettison. It turns away."
		_result(text, "paid", toll)
	else:
		_result("They refuse the offer.", "", 0)


func _result(text: String, outcome: String, paid: int) -> void:
	for child in body.get_children():
		child.queue_free()
	add_title("HAIL")
	add_text(text, 20)
	add_button("Continue...", func(): decided.emit(outcome, paid); close())
