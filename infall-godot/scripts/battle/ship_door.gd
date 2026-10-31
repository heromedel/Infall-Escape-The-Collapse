class_name ShipDoor
extends RefCounted
## A door between two rooms, or an airlock to space. Doors stay shut unless held open from the bridge or
## while crew walk through. Boarders have to break a door when the ship's Doors system is working.

var id: int
var cell_a: Vector2i
var cell_b: Vector2i
var direction: Vector2i
var to_space: bool = false
var held_open: bool = false        # opened from the bridge (or the door panel)
var passing_ticks: int = 0         # open for a moment while someone walks through
var health: float = 100.0          # what a boarder has to break
var broken_open_ticks: int = 0


func is_open() -> bool:
	return held_open or passing_ticks > 0 or broken_open_ticks > 0


func other_cell(cell: Vector2i) -> Vector2i:
	return cell_b if cell == cell_a else cell_a
