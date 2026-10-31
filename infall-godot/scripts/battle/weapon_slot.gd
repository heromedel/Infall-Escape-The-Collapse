class_name WeaponSlot
extends RefCounted
## A weapon fitted to a mount on a ship: whether it is powered, how far it has charged, and what it aims at.
## Aiming follows the genre: aim once and it fires when charged; with autofire it keeps firing at its target.

const SHOT_GAP_TICKS := 5          # 0.25 s between the shots of one volley

var def: WeaponDef
var mount_id: int = -1
var powered: bool = false
var charge: float = 0.0            # ticks charged
var target_ship: Ship = null
var target_room: int = -1
var target_cell := Vector2i(999, 999)   # the tile aimed at; a hit lands on that tile
var target_suit: Battlesuit = null
var beam_start := Vector2.ZERO      # local pixels on the target ship
var beam_end := Vector2.ZERO
var autofire: bool = false
var shots_left: int = 0             # of the volley being fired
var shot_timer: int = 0
var volley_target_ship: Ship = null
var volley_target_room: int = -1
var volley_target_cell := Vector2i(999, 999)
var volley_target_suit: Battlesuit = null
var slide: float = 0.0              # 0 stowed, 1 slid out past the hull (drawing only)
var fired_flash: int = 0


static func create(weapon_def: WeaponDef, mount: int) -> WeaponSlot:
	var slot := WeaponSlot.new()
	slot.def = weapon_def
	slot.mount_id = mount
	return slot


func charge_needed(ship_tech: String) -> float:
	var ticks := float(def.charge_ticks)
	if def.tech != ship_tech:
		ticks *= 1.2               # a weapon works best on a system of its own tech type (GDD 8E)
	return ticks


func is_charged(ship_tech: String) -> bool:
	return charge >= charge_needed(ship_tech)


func has_target() -> bool:
	if target_suit != null:
		return not target_suit.gone
	return target_ship != null and target_room >= 0 and not target_ship.is_gone()


## Aims at one tile of a ship; its room comes with it.
func aim_at(ship: Ship, cell: Vector2i) -> void:
	target_ship = ship
	target_cell = cell
	target_room = ship.room_at(cell)
	target_suit = null


func clear_target() -> void:
	target_ship = null
	target_room = -1
	target_cell = Vector2i(999, 999)
	target_suit = null


func is_firing() -> bool:
	return shots_left > 0
