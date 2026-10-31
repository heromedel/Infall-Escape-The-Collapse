class_name ShipRoom
extends RefCounted
## One room of a ship in play: its tiles, its air, and the fires, breaches and infection in it.

var index: int
var name: String
var cells: Array[Vector2i] = []
var rect: Rect2i
var oxygen: float = 1.0            # 0 to 1
var fires: Dictionary = {}         # Vector2i -> strength, 0 to 100
var breaches: Dictionary = {}      # Vector2i -> repair still needed, 0 to 100
var scorch: Dictionary = {}        # Vector2i -> true where a fire has burned (drawing only)
var infection: float = 0.0         # 0 to 100 (GDD 8G)
var systems: Array = []            # ShipSystem in this room (GDD 5B: a room may hold more than one)
var neighbours: Array[int] = []    # rooms sharing a wall
var fire_system_damage: float = 0.0
var infection_system_damage: float = 0.0


func centre_local(design: ShipDesign) -> Vector2:
	var total := Vector2.ZERO
	for cell in cells:
		total += design.cell_centre(cell)
	return total / max(1, cells.size())


func has_cell(cell: Vector2i) -> bool:
	return rect.has_point(cell)


func is_burning() -> bool:
	return not fires.is_empty()


func is_breached() -> bool:
	return not breaches.is_empty()


func has_trouble() -> bool:
	return is_burning() or is_breached() or infection > 0.0
