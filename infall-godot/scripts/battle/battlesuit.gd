class_name Battlesuit
extends RefCounted
## A crew member out in an EVB battlesuit (race profiles, Mecha 6): it flies to its target, circles it firing
## its arm laser, and heads home when its air runs low. The first hit leaves it damaged and unable to fire;
## a second hit destroys it with its pilot.

var def: WeaponDef
var pilot: CrewMember
var home: Ship
var target: Ship
var target_room: int = -1
var position := Vector2.ZERO
var previous_position := Vector2.ZERO
var state: String = "outbound"      # outbound, attacking, returning
var oxygen_ticks: int = 600
var shot_timer: int = 40
var orbit_angle: float = 0.0
var hits_taken: int = 0
var stun_ticks: int = 0
var gone: bool = false
var side: int = 0


func is_damaged() -> bool:
	return hits_taken > 0
