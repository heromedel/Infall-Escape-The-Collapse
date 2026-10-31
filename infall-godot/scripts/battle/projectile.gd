class_name Projectile
extends RefCounted
## A shot in flight between ships, in world pixels. Whether it misses, hits a shield or hits a room is decided
## when it reaches its target, as in the genre; a miss flies on past the ship and away.

var weapon: WeaponDef
var source: Ship
var target: Ship
var target_room: int = -1
var target_cell := Vector2i(999, 999)   # the tile it was aimed at (shots hit a single tile)
var target_suit: Battlesuit = null
var kind: String = "laser"          # laser, missile, flak, asteroid, suit_laser, defense
var position := Vector2.ZERO
var previous_position := Vector2.ZERO
var velocity := Vector2.ZERO
var aim_point := Vector2.ZERO        # world point it flies at
var missed: bool = false
var resolved: bool = false
var shot_down: bool = false
var life_ticks: int = 0
var damage: int = 1
var side: int = 0
var hunting: Projectile = null       # a defence shot's quarry
var colour := Color.WHITE


func can_be_shot_down() -> bool:
	return kind in ["missile", "asteroid"] and not resolved and not missed
