class_name DebugConsole
extends Control
## The admin console (backtick): commands to test a run quickly, as the project standards ask for.
##   mawjig <amount>   give Mawjig        win               destroy every enemy ship
##   heal              repair and heal    reveal            chart the whole map
##   fight [squad]     start a fight      band <n>          jump to a cluster in band n
##   ship <design>     add a ship         crew <race>       add a crew member
##   help              list the commands

var main: Node
var _input := LineEdit.new()
var _log := RichTextLabel.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	custom_minimum_size = Vector2(0, 300)
	size = Vector2(1920, 300)
	theme = UiKit.theme()
	visible = false
	var back := ColorRect.new()
	back.color = Color(0, 0.02, 0.05, 0.92)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	_log.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_log.offset_bottom = -44
	_log.offset_left = 12
	_log.scroll_following = true
	_log.add_theme_font_size_override("normal_font_size", 16)
	add_child(_log)
	_input.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_input.offset_top = -40
	_input.placeholder_text = "Command (help for a list)"
	_input.text_submitted.connect(_run)
	add_child(_input)
	_say("Infall admin console. Type help.")


func toggle() -> void:
	visible = not visible
	if visible:
		_input.grab_focus()


func _say(text: String) -> void:
	_log.append_text(text + "\n")


func _run(line: String) -> void:
	_input.clear()
	var words := line.strip_edges().split(" ", false)
	if words.is_empty():
		return
	_say("> " + line)
	var run: RunState = main.run
	if run == null and words[0] != "help":
		_say("No run in progress.")
		return
	match words[0]:
		"help":
			_say("mawjig <amount>, win, heal, reveal, fight [squad], band <n>, ship <design>, crew <race>")
		"mawjig":
			run.earn(Mawjig.amount(float(words[1]) if words.size() > 1 else 10.0))
			_say("Mawjig now %s" % Mawjig.format(run.mawjig))
		"win":
			for ship in main.encounter.living(1):
				ship.damage_hull(ship.hull)
			_say("Every enemy ship destroyed.")
		"heal":
			for ship in run.living_ships():
				ship.hull = ship.max_hull
				ship.repair_everything()
				for member in ship.crew:
					member.health = member.max_health
			_say("Squad repaired and healed.")
		"reveal":
			for cluster in run.galaxy.clusters:
				cluster.seen = true
			_say("Map charted.")
		"fight":
			main.start_fight(words[1] if words.size() > 1 else "")
			_say("Fight started.")
		"band":
			var wanted := int(words[1]) if words.size() > 1 else run.band() + 1
			for index in run.galaxy.clusters.size():
				if int(run.galaxy.clusters[index].band) == wanted and not run.galaxy.is_swallowed(index):
					run.current = index
					run.galaxy.clusters[index].visited = true
					main.arrive_at_cluster()
					_say("Moved to %s in band %d." % [run.cluster().name, wanted])
					return
			_say("No cluster found in band %d." % wanted)
		"ship":
			var design := Library.ship(words[1] if words.size() > 1 else "outrider")
			if design:
				run.squad.append(Ship.from_design(design, 0, run.rng, Settings.get_value("terran_conduits", true)))
				main.arrive_at_cluster()
				_say("Added the %s." % design.name)
			else:
				_say("Unknown ship. Known: " + ", ".join(Library.ships.keys()))
		"crew":
			var race := Library.race(words[1] if words.size() > 1 else "terran")
			var ship: Ship = run.living_ships()[0]
			ship.add_crew(CrewMember.create(race, race.random_name(run.rng, [])))
			ship.assign_stations()
			main.arrive_at_cluster()
			_say("Added a %s crew member." % race.singular)
		_:
			_say("Unknown command.")
