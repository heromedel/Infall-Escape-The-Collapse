class_name WeaponDef
extends RefCounted
## One weapon, read from content/weapons/<id>/weapon.xml (GDD 8E, 8F). A weapon is data only: its type and
## effects decide what the battle does with it, so turning a laser into a missile is changing one attribute.
## Battlesuits for the EVB Dock are in the same format with type "suit".

const TICKS_PER_SECOND := 20

var id: String
var name: String
var nickname: String = ""
var race: String = ""
var tech: String = "mechanical"
var type: String = "laser"      # laser, missile, beam, bomb, flak, ion, suit
var power: int = 1
var shots: int = 1
var damage: int = 1
var charge_ticks: int = 200
var cost_per_volley: int = 2    # Mawjig hundredths
var price: int = 0
var fire_chance: int = 0        # percent per room hit
var breach_chance: int = 0
var conduit_chance: int = 0
var infection_chance: int = 0
var ion: int = 0
var stun_ticks: int = 0
var spores: bool = false        # disables the system hit until it is cleared like a repair
var pierce: int = 0
var hull_bonus: bool = false    # double damage to a room without a system
var defensive: bool = false     # shoots down incoming missiles and suits when charged and not aimed
var crew_damage: int = 15       # per point of damage, to every crew member in the room
var beam_length: float = 0.0    # beams: how far the sweep runs, in pixels
var colour: Color = Color("#ff5a3c")
var projectile_speed: float = 900.0
var art_path: String = ""
var art_scale: float = 1.0
var art_anchor := Vector2.ZERO   # the art pixel that sits on the mount point
var art_filter_nearest: bool = false
var description: String = ""
var tagline: String = ""
# Battlesuits
var suit_shot_ticks: int = 60
var suit_oxygen_ticks: int = 600


static func from_xml(node: XmlTree, folder: String) -> WeaponDef:
	var def := WeaponDef.new()
	def.id = node.get_attr("id")
	def.name = node.get_attr("name", def.id)
	def.nickname = node.get_attr("nickname", "")
	def.race = node.get_attr("race", "")
	def.tech = node.get_attr("tech", "mechanical")
	def.type = node.get_attr("type", "laser")
	def.power = node.get_int("power", 1)
	def.shots = node.get_int("shots", 1)
	def.damage = node.get_int("damage", 1)
	def.charge_ticks = int(round(node.get_float("charge", 10.0) * TICKS_PER_SECOND))
	def.cost_per_volley = Mawjig.amount(node.get_float("cost", 0.02))
	def.price = Mawjig.amount(node.get_float("price", 5.0))
	def.fire_chance = node.get_int("fire", 0)
	def.breach_chance = node.get_int("breach", 0)
	def.conduit_chance = node.get_int("conduit", 0)
	def.infection_chance = node.get_int("infection", 0)
	def.ion = node.get_int("ion", 0)
	def.stun_ticks = int(round(node.get_float("stun", 0.0) * TICKS_PER_SECOND))
	def.spores = node.get_bool("spores", false)
	def.pierce = node.get_int("pierce", 0)
	def.hull_bonus = node.get_bool("hull_bonus", false)
	def.defensive = node.get_bool("defensive", false)
	def.crew_damage = node.get_int("crew_damage", 15)
	def.beam_length = node.get_float("beam_length", 0.0)
	def.colour = Color(node.get_attr("colour", "#ff5a3c"))
	def.projectile_speed = node.get_float("speed", 900.0 if def.type != "missile" else 620.0)
	if node.has_attr("art"):
		def.art_path = folder.path_join(node.get_attr("art"))
	def.art_scale = node.get_float("art_scale", 1.0)
	var anchor := node.get_attr("art_anchor", "").split(",", false)
	if anchor.size() == 2:
		def.art_anchor = Vector2(float(anchor[0]), float(anchor[1]))
	def.art_filter_nearest = node.get_attr("art_filter", "") == "nearest"
	def.suit_shot_ticks = int(round(node.get_float("suit_shot_every", 3.0) * TICKS_PER_SECOND))
	def.suit_oxygen_ticks = int(round(node.get_float("suit_oxygen", 30.0) * TICKS_PER_SECOND))
	var description_node := node.first("description")
	if description_node:
		def.description = description_node.get_clean_text()
	def.tagline = node.get_attr("tagline", "")
	return def


func display_name() -> String:
	if nickname.is_empty():
		return name
	return "%s \"%s\"" % [name, nickname]


## The short name that fits on a weapon slot.
func short_name() -> String:
	return nickname if not nickname.is_empty() else name


func charge_seconds() -> float:
	return float(charge_ticks) / TICKS_PER_SECOND


func ignores_shields() -> bool:
	return type in ["missile", "bomb"]


## One line listing what the weapon does, for tooltips and the store.
func stat_line() -> String:
	var parts: PackedStringArray = []
	match type:
		"beam":
			parts.append("Beam, %d damage per room" % damage)
		"suit":
			parts.append("Battlesuit, 1 damage every %.1f s" % (suit_shot_ticks / float(TICKS_PER_SECOND)))
		"flak":
			parts.append("Flak, %d projectiles" % shots)
		_:
			if damage > 0:
				parts.append("%d shot%s x %d damage" % [shots, "" if shots == 1 else "s", damage])
			else:
				parts.append("%d shot%s, no hull damage" % [shots, "" if shots == 1 else "s"])
	if ion > 0:
		parts.append("ion %d" % ion)
	if spores:
		parts.append("spores disable the system")
	if stun_ticks > 0:
		parts.append("stuns crew")
	if fire_chance > 0:
		parts.append("fire %d%%" % fire_chance)
	if breach_chance > 0:
		parts.append("breach %d%%" % breach_chance)
	if conduit_chance > 0:
		parts.append("conduit damage %d%%" % conduit_chance)
	if infection_chance > 0:
		parts.append("infection %d%%" % infection_chance)
	if pierce > 0:
		parts.append("pierces %d shield layer%s" % [pierce, "" if pierce == 1 else "s"])
	if hull_bonus:
		parts.append("double damage to empty rooms")
	if defensive:
		parts.append("shoots down missiles and suits when not aimed")
	if type in ["missile", "bomb"]:
		parts.append("ignores shields")
	return ", ".join(parts)
