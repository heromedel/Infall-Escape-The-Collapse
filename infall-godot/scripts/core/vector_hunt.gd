class_name VectorHunt
extends RefCounted
## The Vector Drive victory (docs/ideas.md, "Vector Drive victory"; GV 2H): the Mecha have built a ship, the Vector
## Frame, around a Mawjig Vector Drive that folds space as far as another galaxy. The squad tracks it down near the
## rim, beats it and takes the drive: fitted to one of its own ships, that ship leaves alone; fitted to The Colony
## Ship at a refit yard, everyone leaves.
##
## The drive is the catch (heromedel, 2026-11-14): destroy the ship while its drive is damaged and the drive is gone.
## The same drive is how the ship gets away: beaten down, it folds out of the fight, unless its drive is damaged.

const SQUAD := "final-vector"
const FRAME := "vector-frame"
const DRIVE := "vector-drive"
const MAX_ESCAPES := 2                 # after this many its drive is too burnt to fold again
const RECOVERS := [0.3, 0.15]          # the share of its hull it gets back after each escape: some, never all
const COLONY_PRICE := 24201            # fitting it to The Colony Ship (Infall: Eco, F19): fixed, in any band
const SCARRED_REPAIR := 454            # a drive that was damaged and mended needs work once fitted
const ALONG_THE_RIM := [300.0, 750.0]  # where it waits: this far along the rim from where the squad would reach it
const FLEES_WITHIN := 400.0            # how far it folds when it gets away: "it hasn't gone far"


## Whether a run can be won this way at all (the Rim Victory setting; the other choice is the old Last Fleet).
static func allowed() -> bool:
	return Settings.get_value("rim_victory", "Vector Drive") == "Vector Drive"


## Whether the Vector Frame is still out there with its drive.
static func at_large(run: RunState) -> bool:
	return allowed() and run.vector_drive == ""


static func drive_held(run: RunState) -> bool:
	return run.vector_drive in ["whole", "scarred"]


## The Vector Frame takes up its place near the rim: a few jumps along it from where the squad would arrive. With a
## trail the map points there; without one the squad reaches the rim first and has to look.
static func place(run: RunState) -> void:
	if run.vector_at >= 0:
		return
	var here: Vector2 = run.cluster().position
	var rim: Array = []
	for index in run.galaxy.clusters.size():
		if run.galaxy.is_rim(index) and not run.galaxy.is_swallowed(index):
			rim.append(index)
	if rim.is_empty():
		return
	rim.sort_custom(func(a, b): return here.distance_squared_to(run.galaxy.clusters[a].position) < here.distance_squared_to(run.galaxy.clusters[b].position))
	var landfall: Vector2 = run.galaxy.clusters[rim[0]].position
	var options: Array = rim.filter(func(index):
		var away: float = landfall.distance_to(run.galaxy.clusters[index].position)
		return away >= ALONG_THE_RIM[0] and away <= ALONG_THE_RIM[1])
	run.vector_at = options[run.rng.randi_range(0, options.size() - 1)] if not options.is_empty() else rim[0]


## It folds out of a fight to somewhere close by: outward or level with where it was, never a store.
static func flee(run: RunState) -> void:
	var from: Dictionary = run.cluster()
	var options: Array = []
	var fallback: Array = []
	for index in run.galaxy.clusters.size():
		var cluster: Dictionary = run.galaxy.clusters[index]
		if index == run.current or run.galaxy.is_swallowed(index) or cluster.get("store", false) or cluster.kind in ["store", "opening"]:
			continue
		var away: float = from.position.distance_to(cluster.position)
		if away > FLEES_WITHIN:
			continue
		fallback.append(index)
		if float(cluster.radius) >= float(from.radius) - 60.0:
			options.append(index)
	if options.is_empty():
		options = fallback
	if not options.is_empty():
		run.vector_at = options[run.rng.randi_range(0, options.size() - 1)]
		run.galaxy.clusters[run.vector_at].event_done = false


## The collapse reaches where it waits: it moves to the rim ahead of it.
static func keep_ahead_of_the_collapse(run: RunState) -> void:
	if run.vector_at >= 0 and run.galaxy.is_swallowed(run.vector_at) and at_large(run):
		run.vector_at = -1
		place(run)


## What the squad knows of where it is (Infall: Lori's map lines).
static func map_lines(run: RunState) -> PackedStringArray:
	var out: PackedStringArray = []
	if not allowed() or not run.vector_goal:
		return out
	match run.vector_drive:
		"lost":
			out.append("The Mawjig Vector Drive is gone, and the way out it offered with it.")
		"whole", "scarred":
			out.append("The Mawjig Vector Drive is in the hold%s." % (", scarred" if run.vector_drive == "scarred" else ""))
			out.append("Fitted to one of your ships, at any store, that ship makes the jump and nobody else does (%s Mawjig)." % Mawjig.format(scout_price(run)))
			out.append("A refit yard can fit it to The Colony Ship: everyone makes the jump (%s Mawjig)." % Mawjig.format(colony_price(run)))
		_:
			var knows: bool = run.vector_at >= 0 and (run.vector_trail > 0 or run.vector_met > 0)
			if not knows:
				out.append("The Vector Frame: somewhere near the rim. Find its trail.")
			elif run.vector_at == run.current:
				out.append("The Vector Frame: it is here.")
			else:
				var toward: Vector2 = run.galaxy.clusters[run.vector_at].position - run.cluster().position
				var direction: String = RimTech.COMPASS[posmod(int(round(toward.angle() / (TAU / 8.0))), 8)]
				out.append("The Vector Frame: last seen heading %s of you." % direction)
				if run.vector_trail >= 2 or run.vector_met > 0:
					out.append("Your charts put it at %s." % run.galaxy.clusters[run.vector_at].name)
	return out


## Fitting the drive to one of the squad's ships: the usual refit, a quarter of the system's price.
static func scout_price(run: RunState) -> int:
	var def := Library.system(DRIVE)
	var price: int = Mawjig.no_trailing_zero(int(round((def.buy_price if def else 3631) * Refit.MOVE_SHARE)))
	return price + (SCARRED_REPAIR if run.vector_drive == "scarred" else 0)


static func colony_price(run: RunState) -> int:
	return COLONY_PRICE + (SCARRED_REPAIR if run.vector_drive == "scarred" else 0)


## Why the drive can't be fitted here to a ship (or, with no ship, to The Colony Ship), or "".
static func fit_refusal(run: RunState, ship: Ship) -> String:
	if not drive_held(run):
		return "The Mawjig Vector Drive isn't in the hold."
	if ship == null:
		if not Refit.has_yard(run.cluster()):
			return "Only a refit yard can fit it to The Colony Ship."
		if run.mawjig < colony_price(run):
			return "Not enough Mawjig."
		return ""
	if ship.is_gone() or ship.is_mercenary():
		return "It can't be fitted to that ship."
	if run.mawjig < scout_price(run):
		return "Not enough Mawjig."
	return ""


## Fits it: the run is won, by the one ship ("vector") or by The Colony Ship ("fold").
static func fit(run: RunState, ship: Ship) -> bool:
	if not fit_refusal(run, ship).is_empty() or not run.spend(colony_price(run) if ship == null else scout_price(run)):
		return false
	run.vector_drive = "fitted"
	run.victory = "fold" if ship == null else "vector"
	run.vector_ship = ship.name if ship else "The Colony Ship"
	return true
