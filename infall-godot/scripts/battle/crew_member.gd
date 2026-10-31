class_name CrewMember
extends RefCounted
## One crew member: who they are (race, name, skills) and where they are (ship, tile, path, current task).
## Skills follow GDD 7H: one curve for every skill, 100 XP to level 1 and 250 to level 2, at the race's rate.

const SKILLS := ["piloting", "engines", "shields", "weapons", "repair", "combat"]
const LEVEL_XP := [100.0, 250.0]
const BASE_SPEED_TILES := 2.6      # tiles a second at speed 1.0

var name: String
var race: RaceDef
var health: float = 100.0
var max_health: float = 100.0
var xp: Dictionary = {}            # skill -> XP, kept in decimals, shown whole
var side: int = 0                  # 0 player, 1 enemy
var home: Ship                     # the ship whose crew they are
var ship: Ship                     # the ship they are on now (boarding changes it)
var cell: Vector2i                 # the tile they stand on or are leaving
var position := Vector2.ZERO        # local pixels on `ship`
var previous_position := Vector2.ZERO
var path: Array[Vector2i] = []
var destination := Vector2i(999, 999)
var station_room: int = -1         # where "return to stations" sends them
var station_preference: String = ""
var task: String = "idle"           # idle, walking, manning, repairing, fighting, extinguishing, patching
var healing: bool = false          # a medbay is healing them this tick, whatever their task
var stun_ticks: int = 0
var door_wait: ShipDoor = null
var dead: bool = false
var in_suit: bool = false
var teleporting_ticks: int = 0
var integrate_ticks: int = 0       # Mecha: time spent getting into a system
var suffocating: bool = false
var attack_cooldown: int = 0
var kills: int = 0
var selected: bool = false
var player_ordered: bool = false   # walking where the player sent them


static func create(race_def: RaceDef, crew_name: String) -> CrewMember:
	var member := CrewMember.new()
	member.race = race_def
	member.name = crew_name
	member.max_health = race_def.max_health
	member.health = member.max_health
	for skill in SKILLS:
		member.xp[skill] = 0.0
	return member


func skill_level(skill: String) -> int:
	var points: float = xp.get(skill, 0.0)
	if points >= LEVEL_XP[1]:
		return 2
	if points >= LEVEL_XP[0]:
		return 1
	return 0


## Adds XP at the race's rate; returns true when a skill level was gained.
func gain_xp(skill: String, amount: float) -> bool:
	if skill.is_empty() or not xp.has(skill):
		return false
	var before := skill_level(skill)
	xp[skill] = minf(LEVEL_XP[1], xp[skill] + amount * race.xp_rate)
	return skill_level(skill) > before


func speed_pixels_per_tick() -> float:
	return BASE_SPEED_TILES * race.speed * ShipDesign.TILE / 20.0


func is_active() -> bool:
	return not dead and not in_suit and teleporting_ticks <= 0


func can_act() -> bool:
	return is_active() and stun_ticks <= 0


func is_moving() -> bool:
	return not path.is_empty()


func health_fraction() -> float:
	return clampf(health / max_health, 0.0, 1.0)


func is_boarding() -> bool:
	return ship != home


func to_save() -> Dictionary:
	return {"name": name, "race": race.id, "health": health, "xp": xp.duplicate(), "station": station_room}


static func from_save(data: Dictionary) -> CrewMember:
	var member := create(Library.race(data.get("race", "terran")), data.get("name", "Crew"))
	member.health = data.get("health", member.max_health)
	var saved_xp: Dictionary = data.get("xp", {})
	for skill in saved_xp:
		member.xp[skill] = float(saved_xp[skill])
	member.station_room = int(data.get("station", -1))
	return member
