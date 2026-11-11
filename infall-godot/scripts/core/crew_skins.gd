class_name CrewSkins
extends RefCounted
## Crew subtypes (GV 7F): the colours a crew member wears, one for each part of their race's sheet, written with a
## slash between them, e.g. a Tentauri's "blue/forest" for bell and tentacles. A race lists its parts, the colours
## each can take and its planned subtypes in its race.xml; a race that lists none has no subtypes.
##
## A squad hands out the planned subtypes first, then the other combinations of the listed colours, and never one
## somebody in the squad already wears. Past that it makes colours up.

const MADE_UP_TRIES := 3          # a made-up subtype too like one already worn is thrown twice; the third stands
const LOOKS_ALIKE := 25.0 / 360.0  # two colours whose hues are nearer than this look alike


## Gives a subtype to every crew member of these ships who has none and whose race has them.
static func dress(ships: Array, rng: RandomNumberGenerator) -> void:
	for ship in ships:
		for member in ship.crew:
			if member.subtype.is_empty() and not member.race.skin_parts.is_empty():
				member.subtype = pick(member.race, worn(ships, member.race), rng)


## The subtypes this race's living crew wear on these ships.
static func worn(ships: Array, race: RaceDef) -> Array:
	var subtypes: Array = []
	for ship in ships:
		for member in ship.crew:
			if member.race == race and not member.dead and not member.subtype.is_empty():
				subtypes.append(member.subtype)
	return subtypes


## A subtype for a newcomer: a planned one nobody wears, else another combination nobody wears, else a made-up one.
## "" for a race without subtypes.
static func pick(race: RaceDef, already_worn: Array, rng: RandomNumberGenerator) -> String:
	if race.skin_parts.is_empty():
		return ""
	for choices in [Array(race.subtypes), _combinations(race)]:
		var free: Array = choices.filter(func(subtype): return not already_worn.has(subtype))
		if not free.is_empty():
			return free[rng.randi_range(0, free.size() - 1)]
	var made_up := ""
	for attempt in MADE_UP_TRIES:
		made_up = _made_up(race, rng)
		if not already_worn.any(func(other): return _look_alike(race, made_up, other)):
			break
	return made_up


## The colour codes to change in the race's sheet for a subtype: {the sheet's code: the code worn in its place}.
static func colour_changes(race: RaceDef, subtype: String) -> Dictionary:
	var changes := {}
	var wears := subtype.split("/", false)
	for index in mini(wears.size(), race.skin_parts.size()):
		var part: Dictionary = race.skin_parts[index]
		var tones := _tones(part, wears[index])
		for tone in part.sheet_tones.size():
			changes[part.sheet_tones[tone]] = tones[tone]
	return changes


## A part's tones in one colour, lightest first: a listed colour's own, or for a made-up colour (a colour code) the
## sheet's tones turned to that hue. A name the race no longer lists keeps the sheet's tones.
static func _tones(part: Dictionary, colour: String) -> PackedStringArray:
	if part.colours.has(colour):
		return part.colours[colour]
	if not colour.begins_with("#"):
		return part.sheet_tones
	var turn := Color(colour).h - _hue(part.sheet_tones)
	var tones := PackedStringArray()
	for code in part.sheet_tones:
		var tone := Color(code)
		tones.append("#" + Color.from_hsv(fposmod(tone.h + turn, 1.0), tone.s, tone.v).to_html(false))
	return tones


## The hue of a set of tones: that of its middle tone.
static func _hue(tones: PackedStringArray) -> float:
	return Color(tones[tones.size() / 2]).h


static func _look_alike(race: RaceDef, subtype: String, other: String) -> bool:
	var wears := subtype.split("/", false)
	var other_wears := other.split("/", false)
	for index in race.skin_parts.size():
		if index >= wears.size() or index >= other_wears.size():
			return false
		var part: Dictionary = race.skin_parts[index]
		var apart := absf(_hue(_tones(part, wears[index])) - _hue(_tones(part, other_wears[index])))
		if minf(apart, 1.0 - apart) >= LOOKS_ALIKE:
			return false
	return true


static func _made_up(race: RaceDef, rng: RandomNumberGenerator) -> String:
	var wears := PackedStringArray()
	for part in race.skin_parts:
		wears.append("#" + Color.from_hsv(rng.randf(), 0.6, 0.85).to_html(false))
	return "/".join(wears)


## Every combination of the listed colours, one for each part.
static func _combinations(race: RaceDef) -> Array:
	var combinations: Array = [""]
	for part in race.skin_parts:
		var longer: Array = []
		for start in combinations:
			for colour in part.colours:
				longer.append(colour if start.is_empty() else start + "/" + colour)
		combinations = longer
	return combinations
