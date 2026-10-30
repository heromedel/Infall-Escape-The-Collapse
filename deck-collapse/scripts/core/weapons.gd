## Single weapons: reading and writing them, and what follows from their parts (speed, price, Mawjig per card, card
## text). A weapon is a Dictionary: { id, name, kind, power, shots, damage, speed, rooms, fire, breach, pierce,
## multi_target, chain, defensive, spores, stun, mind, tech } plus what its family gives it (shields, ion,
## uses_missile, wounds_crew, never_misses) and what it costs (price, ammo).
class_name Weapons
extends RefCounted

## The weapon-budget-table's cooldown that one card stands for: cards = COOLDOWN_PER_CARD ÷ cooldown.
const COOLDOWN_PER_CARD := 36.0
const MAX_SPEED := 5
const SLOTS_PER_SYSTEM := 4
## Difficulty bands run 1 to 8 (GDD: about 8 bands, each about 10 clusters deep).
const MAX_BAND := 8
## Old ship files named a weapon by kind and Type; these are the weapons they become.
const LEGACY := {
	"laser": ["spark-laser", "triad-laser", "storm-laser"], "heavy": ["heavy-laser", "heavy-laser", "twin-heavy"],
	"ion": ["ion-burst", "twin-ion", "ion-storm"], "missile": ["torpedo", "lance-torpedo", "breach-torpedo"],
	"beam": ["cutter-beam", "cleaver-beam", "halberd-beam"], "chain": ["chain-repeater", "chain-repeater", "chain-repeater"],
}
const FLAGS := {"multiTarget": "multi_target", "chain": "chain", "defensive": "defensive", "spores": "spores",
	"stun": "stun", "mind": "mind"}
const NUMBERS := {"power": 1, "shots": 1, "damage": 1, "rooms": 1, "fire": 0, "breach": 0, "pierce": 0, "crewDamage": 0}


## A weapon from XML attributes, on top of an optional premade one (attributes override it).
static func from_attributes(attrs: Dictionary, base: Dictionary = {}) -> Dictionary:
	var weapon := base.duplicate()
	weapon.id = attrs.get("id", weapon.get("id", ""))
	weapon.kind = attrs.get("kind", attrs.get("family", weapon.get("kind", "laser")))
	weapon.name = attrs.get("name", weapon.get("name", Catalog.weapon_family(weapon.kind).name))
	weapon.tech = attrs.get("tech", weapon.get("tech", ""))
	for key in NUMBERS:
		weapon[key] = int(attrs.get(key, weapon.get(key, NUMBERS[key])))
	for key in FLAGS:
		var field: String = FLAGS[key]
		weapon[field] = attrs.get(key, "true" if weapon.get(field, false) else "false") == "true"
	weapon.rarity = int(attrs.get("rarity", weapon.get("rarity", 1)))
	var bands := String(attrs.get("bands", "%d-%d" % [weapon.get("band_min", 1), weapon.get("band_max", MAX_BAND)])).split("-")
	weapon.band_min = int(bands[0])
	weapon.band_max = int(bands[bands.size() - 1])
	return finish(weapon, int(attrs.get("speed", weapon.get("speed", 0))))


## Fills in what a weapon's family gives it, its speed (0: the default from its cooldown), price and Mawjig per card.
static func finish(weapon: Dictionary, speed: int = 0) -> Dictionary:
	var family := Catalog.weapon_family(weapon.kind)
	weapon.shields = family.shields
	weapon.ion = family.ion
	weapon.uses_missile = family.uses_missile
	weapon.wounds_crew = family.wounds_crew
	weapon.never_misses = family.never_misses
	weapon.bomb = family.bomb
	if weapon.kind != "beam":
		weapon.rooms = 1
	weapon.speed = clampi(speed if speed > 0 else roundi(COOLDOWN_PER_CARD / cooldown(weapon)), 1, MAX_SPEED)
	weapon.price = price(weapon)
	weapon.ammo = ammo(weapon)
	return weapon


## Whether a weapon may turn up (in stores and enemy loadouts) in this band. New ideas come in slowly.
static func allowed_in_band(weapon: Dictionary, band: int) -> bool:
	return band >= int(weapon.get("band_min", 1)) and band <= int(weapon.get("band_max", MAX_BAND))


## How often a store offers the weapon among the others it may stock: its rarity's weight (rules.xml, <rarity>).
static func store_weight(weapon: Dictionary) -> float:
	return Catalog.by_skill(Catalog.rule("rarity", "weights", [0, 5, 4, 3, 2, 1]), int(weapon.get("rarity", 1)))


## Only the attributes that make the weapon, for ship files.
static func to_xml(weapon: Dictionary, depth: int = 2) -> String:
	var parts: Array[String] = []
	if weapon.get("id", "") != "":
		parts.append('id="%s"' % XmlTree.escape(weapon.id))
	parts.append('name="%s"' % XmlTree.escape(weapon.name))
	parts.append('kind="%s"' % weapon.kind)
	for key in NUMBERS:
		if int(weapon[key]) != NUMBERS[key] or key in ["power", "shots", "damage"]:
			parts.append('%s="%d"' % [key, weapon[key]])
	parts.append('speed="%d"' % weapon.speed)
	for key in FLAGS:
		if weapon.get(FLAGS[key], false):
			parts.append('%s="true"' % key)
	if weapon.get("tech", "") != "":
		parts.append('tech="%s"' % XmlTree.escape(weapon.tech))
	if int(weapon.get("rarity", 1)) != 1:
		parts.append('rarity="%d"' % weapon.rarity)
	if weapon.get("band_min", 1) != 1 or weapon.get("band_max", MAX_BAND) != MAX_BAND:
		parts.append('bands="%d-%d"' % [weapon.band_min, weapon.band_max])
	return "%s<weapon %s/>" % ["  ".repeat(depth), " ".join(parts)]


## Damage a card does across its shots (beams: across the systems they sweep).
static func damage_per_card(weapon: Dictionary) -> int:
	return weapon.damage * weapon.shots * (weapon.rooms if weapon.kind == "beam" else 1)


## The weapon-budget-table cooldown in seconds, built from the weapon's parts.
static func cooldown(weapon: Dictionary) -> float:
	var shots := float(weapon.shots)
	var seconds: float = 7.0 + 2.0 * damage_per_card(weapon)
	if weapon.ion:
		seconds += 2.5 * shots
	if weapon.spores:
		seconds += 2.5 * shots
	if weapon.stun:
		seconds += 2.0 * shots
	if weapon.mind:
		seconds += 4.0 * shots  # judgment: mind control is worth more than a stun
	seconds += 2.0 * weapon.crewDamage * shots * (weapon.rooms if weapon.kind == "beam" else 1)  # judgment: as damage
	seconds += 3.0 * shots * weapon.fire / 100.0 + 1.0 * shots * weapon.breach / 100.0 + 1.4 * weapon.pierce
	match weapon.kind:
		"beam": seconds += 5.0
		"bomb": seconds += 5.0
		"flak": seconds -= 3.0
	if weapon.multi_target:
		seconds += 1.0
	return maxf(3.0, seconds)


## Store price in Mawjig, from weapon-budget-table.md: power, plus the damage and effect rates over its cooldown
## (a faster weapon is worth more), plus specials. The cooldown is the table's exact one; a weapon given more or fewer
## cards than its cooldown suggests counts as that much faster or slower.
static func price(weapon: Dictionary) -> float:
	var seconds := cooldown(weapon)
	var suggested := clampi(roundi(COOLDOWN_PER_CARD / seconds), 1, MAX_SPEED)
	var per_ten := 10.0 / (seconds * suggested / float(weapon.speed))
	var shots := float(weapon.shots)
	var total: float = 1.41 + 4.09 * weapon.power + 1.16 * damage_per_card(weapon) * per_ten
	if weapon.ion:
		total += 0.54 * shots * per_ten
	if weapon.spores:
		total += 0.54 * shots * per_ten
	if weapon.stun:
		total += 1.21 * shots * per_ten
	if weapon.mind:
		total += 2.42 * shots * per_ten  # judgment: twice a stun
	total += 1.16 * weapon.crewDamage * shots * (weapon.rooms if weapon.kind == "beam" else 1) * per_ten  # judgment: as damage
	total += 1.15 * shots * (weapon.fire + weapon.breach) / 100.0 * per_ten + 0.75 * weapon.pierce
	match weapon.kind:
		"beam": total += 0.24
		"bomb": total += 5.54
		"flak": total += 1.38
	if weapon.defensive:
		total += 5.32
	if weapon.multi_target:
		total *= 1.25
	return _no_trailing_zero(total)


## Mawjig to fire one card, from mawjig-cost-table.md: the family's base per shot (beams per system swept), half
## the base again per damage above 1, plus effects, times shots; multi-target × 1.25.
static func ammo(weapon: Dictionary) -> float:
	var base := float(Catalog.weapon_family(weapon.kind).base)
	var per_shot: float = base * (1.0 + 0.5 * maxi(0, weapon.damage - 1))
	per_shot += 0.03 * weapon.fire / 100.0 + 0.03 * weapon.breach / 100.0 + 0.04 * weapon.pierce
	if weapon.ion:
		per_shot += 0.02
	if weapon.spores:
		per_shot += 0.04
	if weapon.stun:
		per_shot += 0.02
	if weapon.mind:
		per_shot += 0.08
	if weapon.crewDamage > 0:
		per_shot += 0.05  # mawjig-cost-table.md: Kill (bio)
	var volley: float = per_shot * weapon.shots * (weapon.rooms if weapon.kind == "beam" else 1)
	if weapon.multi_target:
		volley *= 1.25
	return _no_trailing_zero(volley)


## What a weapon does, in one line: "Laser · 2 shots · 1 damage · multi-target".
static func summary(weapon: Dictionary) -> String:
	var parts: Array[String] = [Catalog.weapon_family(weapon.kind).name]
	if weapon.kind == "beam":
		parts.append("%d damage to %d system%s" % [weapon.damage, weapon.rooms, "" if weapon.rooms == 1 else "s in a row"])
	else:
		parts.append("%d shot%s" % [weapon.shots, "" if weapon.shots == 1 else "s"])
		if weapon.damage > 0:
			parts.append("%d damage" % weapon.damage)
	if weapon.crewDamage > 0:
		parts.append("%d to crew" % weapon.crewDamage)
	for special in specials(weapon):
		parts.append(special)
	return " · ".join(parts)


## Its specials as short words: "multi-target", "breach 20%", "spores" …
static func specials(weapon: Dictionary) -> Array[String]:
	var found: Array[String] = []
	if weapon.multi_target and Settings.value("multi_target_lasers") == "On":
		found.append("multi-target")
	if weapon.ion:
		found.append("ion")
	if weapon.pierce > 0:
		found.append("pierce %d" % weapon.pierce)
	for key in ["spores", "stun", "mind", "chain", "defensive"]:
		if weapon[key]:
			found.append({"mind": "mind control"}.get(key, key))
	if weapon.fire > 0:
		found.append("fire %d%%" % weapon.fire)
	if weapon.breach > 0:
		found.append("breach %d%%" % weapon.breach)
	return found


## The card's rules text: the summary, then what its family and specials do.
static func card_text(weapon: Dictionary) -> String:
	var lines: Array[String] = [summary(weapon) + "."]
	if weapon.kind == "beam" and weapon.rooms > 1:
		lines.append("Aim it left or right.")
	lines.append(Catalog.weapon_family(weapon.kind).summary)
	if weapon.multi_target and Settings.value("multi_target_lasers") == "On":
		lines.append("Each shot can aim at its own system.")
	if weapon.spores:
		lines.append("Spores knock the system offline until a Repair clears them.")
	if weapon.stun:
		lines.append("Crew there lose their next turn.")
	if weapon.mind:
		lines.append("Takes over one crew member there for a turn.")
	if weapon.defensive:
		lines.append("While its system works, it shoots down one enemy torpedo each enemy turn.")
	if weapon.crewDamage > 0:
		lines.append("Everyone in the hit system loses %d health." % weapon.crewDamage)
	if weapon.chain:
		lines.append("Each time it fires, a temporary copy joins your deck.")
	return " ".join(lines)


## What a weapon looks like on cards and in shots: laser, heavy, ion, missile, beam, chain, flak, spore or mind.
static func art(weapon: Dictionary) -> String:
	if weapon.kind == "bomb":
		return "bomb"
	if weapon.spores:
		return "spore"
	if weapon.mind:
		return "mind"
	if weapon.chain:
		return "chain"
	if weapon.kind == "laser" and weapon.damage >= 2:
		return "heavy"
	return weapon.kind


## Mawjig amounts never end in a zero (mawjig-cost-table.md): an x.x0 price moves up 0.01.
static func _no_trailing_zero(amount: float) -> float:
	var cents := roundi(amount * 100.0)
	if cents % 10 == 0:
		cents += 1
	return cents / 100.0
