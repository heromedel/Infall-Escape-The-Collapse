class_name ShipDesign
extends RefCounted
## A ship's floor layout and starting data, read from content/ships/<id>/ship.xml (GDD 5F-5L), or from a
## loadout of it, loadout.<ship>.<loadout>.xml, which patches or replaces the ship (GDD 5J).
##
## Coordinates in the file count tiles from the ship's centre (GDD 5G). Under "Tile" centring tile 0 exists
## and the centre is the middle of it; under "Point" the centre is a grid point and there is no 0. Both are
## turned into plain cells here, so nothing else in the game needs to know which centring a file used.

const TILE := 35.0
const DIRECTIONS := {"north": Vector2i(0, -1), "east": Vector2i(1, 0), "south": Vector2i(0, 1), "west": Vector2i(-1, 0)}
const CONDUIT_BITS := {"N": 1, "E": 2, "S": 4, "W": 8}

var id: String
var base_id: String              # the ship a loadout came from; its own id for a base ship
var name: String
var class_text: String = ""
var race: String = "terran"
var faction: String = ""          # whose colours it flies: gatos, pirate, mecha, ...
var style: String = ""            # how a missing hull is drawn: terran, pirate, mecha, tentauri, ...
var hull: int = 10
var value: int = 10000           # Mawjig hundredths; what a wreck pays from (GDD 8I)
var reactor_type: String = "pool"   # pool (bars), core (the AZC and conduits), none (each system powers itself)
var reactor_level: int = 8
var cell_offset := Vector2.ZERO   # local pixel position of cell (0,0)'s top-left corner
var rooms: Array = []            # {id, name, cells: Array[Vector2i], rect: Rect2i}
var cell_room: Dictionary = {}   # Vector2i -> room index
var doors: Array = []            # {id, a: Vector2i, b: Vector2i, to_space: bool, direction: Vector2i}
var systems: Array = []          # {id, label, cell, room, wall, level, own_power}
var conduits: Dictionary = {}    # Vector2i -> bit mask of N, E, S, W
var mounts: Array = []           # {id, position: Vector2 (local pixels), slide: Vector2}
var weapons: Array = []          # {id, mount}
var suits: Array = []            # battlesuit ids for an EVB Dock
var plan: CaptainPlan = null     # the captain's plan from <ai>, if the file has one
var crew: Array = []             # {race, name, station}
var art_path: String = ""
var art_scale: float = 1.0
var art_centre := Vector2.ZERO   # the art pixel (at scale 1) that sits on the ship's centre
var art_nearest: bool = false
var description: String = ""
var problems: PackedStringArray = []
var folder: String = ""


## Reads a base ship file.
static func from_file(path: String) -> ShipDesign:
	var node := XmlTree.load_file(path)
	if node == null:
		return null
	var design := ShipDesign.new()
	design.folder = path.get_base_dir()
	design._read(node)
	design.base_id = design.id
	return design


## Reads a loadout file over its ship's XML (GDD 5J): Patch keeps everything it doesn't list; Replace starts clean.
static func from_loadout(loadout_path: String, ship_path: String) -> ShipDesign:
	var patch := XmlTree.load_file(loadout_path)
	var base := XmlTree.load_file(ship_path)
	if patch == null or base == null:
		return null
	var merged: XmlTree
	if patch.get_attr("inherit", "patch").to_lower() == "replace":
		merged = patch
	else:
		merged = _patch_tree(base, patch)
	var design := ShipDesign.new()
	design.folder = ship_path.get_base_dir()
	design._read(merged)
	design.base_id = base.get_attr("id")
	design.id = design.base_id + "." + patch.get_attr("id")
	design.name = patch.get_attr("name", design.name)
	return design


static func _entry_key(node: XmlTree) -> String:
	match node.tag:
		"room", "door", "mount":
			return node.tag + ":" + node.get_attr("id")
		"system":
			return "system:" + node.get_attr("id") + ":" + node.get_attr("label")
		"reactor", "art", "weapons", "suits", "crew", "description", "ai":
			return node.tag
	return ""


static func _patch_tree(base: XmlTree, patch: XmlTree) -> XmlTree:
	var merged := XmlTree.new()
	merged.tag = "ship"
	merged.attributes = base.attributes.duplicate()
	for key in patch.attributes:
		if key not in ["inherit", "ship", "id"]:
			merged.attributes[key] = patch.attributes[key]
	var order: Array[String] = []
	var entries := {}
	var conduit_text := ""
	for child in base.children:
		if child.tag == "conduits":
			conduit_text = child.text
			continue
		var key := _entry_key(child)
		if key.is_empty():
			continue
		order.append(key)
		entries[key] = child
	var conduit_patch := ""
	for child in patch.children:
		if child.tag == "conduits":
			conduit_patch = child.text
			continue
		var key := _entry_key(child)
		if key.is_empty():
			continue
		if child.get_bool("removed"):
			entries.erase(key)
			continue
		if not entries.has(key):
			order.append(key)
		entries[key] = child
	for key in order:
		if entries.has(key):
			merged.children.append(entries[key])
	var conduits_node := XmlTree.new()
	conduits_node.tag = "conduits"
	conduits_node.text = conduit_text + "\n" + conduit_patch
	merged.children.append(conduits_node)
	return merged


func _read(node: XmlTree) -> void:
	id = node.get_attr("id")
	name = node.get_attr("name", id)
	class_text = node.get_attr("class", "")
	race = node.get_attr("race", "terran")
	faction = node.get_attr("faction", race)
	style = node.get_attr("style", faction)
	hull = node.get_int("hull", 10)
	value = Mawjig.amount(node.get_float("value", 100.0))
	var centre_mode := node.get_attr("center", "Tile")
	var point_x := node.get_attr("center_x", centre_mode) == "Point"
	var point_y := node.get_attr("center_y", centre_mode) == "Point"
	cell_offset = Vector2(0.0 if point_x else -TILE * 0.5, 0.0 if point_y else -TILE * 0.5)
	var to_cell := func(text: String) -> Vector2i:
		var parts := text.split(",")
		var x := int(parts[0])
		var y := int(parts[1])
		if point_x and x > 0:
			x -= 1
		if point_y and y > 0:
			y -= 1
		return Vector2i(x, y)

	for child in node.children:
		match child.tag:
			"reactor":
				reactor_type = child.get_attr("type", "pool")
				reactor_level = child.get_int("level", 8)
			"art":
				art_path = folder.path_join(child.get_attr("hull")) if child.has_attr("hull") else ""
				art_scale = child.get_float("scale", 1.0)
				var centre_parts := child.get_attr("center", "0,0").split(",")
				art_centre = Vector2(float(centre_parts[0]), float(centre_parts[1]))
				art_nearest = child.get_attr("filter", "") == "nearest"
			"room":
				var corner_a: Vector2i = to_cell.call(child.get_attr("from"))
				var corner_b: Vector2i = to_cell.call(child.get_attr("to", child.get_attr("from")))
				var rect := Rect2i(Vector2i(mini(corner_a.x, corner_b.x), mini(corner_a.y, corner_b.y)), Vector2i.ZERO)
				rect.end = Vector2i(maxi(corner_a.x, corner_b.x) + 1, maxi(corner_a.y, corner_b.y) + 1)
				var cells: Array[Vector2i] = []
				for y in range(rect.position.y, rect.end.y):
					for x in range(rect.position.x, rect.end.x):
						cells.append(Vector2i(x, y))
				rooms.append({"id": child.get_int("id"), "name": child.get_attr("name", ""), "cells": cells, "rect": rect})
			"system":
				systems.append({
					"id": child.get_attr("id"),
					"label": child.get_attr("label", ""),
					"cell": to_cell.call(child.get_attr("tile")),
					"wall": child.get_attr("wall", "north").to_lower(),
					"level": child.get_int("level", 1),
					"own_power": child.get_int("own_power", 0),
					"room": -1,
				})
			"door":
				var cell: Vector2i = to_cell.call(child.get_attr("tile"))
				var direction: Vector2i = DIRECTIONS.get(child.get_attr("facing", "south").to_lower(), Vector2i(0, 1))
				doors.append({"id": child.get_int("id"), "a": cell, "b": cell + direction, "direction": direction, "to_space": false})
			"conduits":
				var entry_pattern := RegEx.create_from_string("\\([^)]*\\)")
				for found in entry_pattern.search_all(child.text):
					_read_conduit(found.get_string(), to_cell)
			"mount":
				var slide_name := child.get_attr("slide", "up")
				var slide := {"up": Vector2.UP, "down": Vector2.DOWN, "left": Vector2.LEFT, "right": Vector2.RIGHT}.get(slide_name, Vector2.UP) as Vector2
				var position := Vector2.ZERO
				if child.has_attr("x"):
					position = Vector2(child.get_float("x"), child.get_float("y")) - art_centre
				elif child.has_attr("tile"):
					var mount_cell: Vector2i = to_cell.call(child.get_attr("tile"))
					position = cell_centre(mount_cell) + slide * (TILE * 0.5 + child.get_float("out", 14.0))
				mounts.append({"id": child.get_int("id"), "position": position, "slide": slide})
			"weapons":
				weapons.clear()
				for weapon_node in child.all("weapon"):
					weapons.append({"id": weapon_node.get_attr("id"), "mount": weapon_node.get_int("mount", -1)})
			"suits":
				suits.clear()
				for suit_node in child.all("suit"):
					suits.append(suit_node.get_attr("id"))
			"crew":
				crew.clear()
				for member in child.all("member"):
					for copy in member.get_int("count", 1):
						crew.append({"race": member.get_attr("race", race), "name": member.get_attr("name", ""), "station": member.get_attr("station", "")})
			"description":
				description = child.get_clean_text()
			"ai":
				plan = CaptainPlan.read(child)
				for problem in plan.problems:
					problems.append("%s: captain plan: %s" % [id, problem])
	_link_layout()


func _read_conduit(entry: String, to_cell: Callable) -> void:
	if entry.is_empty() or not entry.begins_with("("):
		return
	var parts := entry.trim_prefix("(").trim_suffix(")").split(",")
	if parts.size() < 2:
		return
	var cell: Vector2i = to_cell.call(parts[0] + "," + parts[1])
	if parts.size() > 2 and parts[2].strip_edges().to_lower() == "remove":
		conduits.erase(cell)
		return
	var mask := 0
	for index in range(2, parts.size()):
		mask |= int(CONDUIT_BITS.get(parts[index].strip_edges().to_upper(), 0))
	if parts.size() == 2:
		mask = 15   # a tile with no directions is a full intersection (GDD 5H)
	conduits[cell] = mask


## Ties systems and doors to rooms and records anything the file got wrong (GDD 5J: the game says why).
func _link_layout() -> void:
	cell_room.clear()
	for index in rooms.size():
		for cell in rooms[index].cells:
			cell_room[cell] = index
	for system in systems:
		system.room = cell_room.get(system.cell, -1)
		if system.room < 0:
			problems.append("%s sits on tile %s, which is in no room." % [system.id, str(system.cell)])
	var kept: Array = []
	for door in doors:
		var room_a: int = cell_room.get(door.a, -1)
		var room_b: int = cell_room.get(door.b, -1)
		if room_a < 0 and room_b < 0:
			problems.append("Door %d is not on any room." % door.id)
			continue
		if room_a < 0:
			var swap: Vector2i = door.a
			door.a = door.b
			door.b = swap
			door.direction = -door.direction
		door.to_space = cell_room.get(door.b, -1) < 0
		if not door.to_space and cell_room[door.a] == cell_room[door.b]:
			problems.append("Door %d joins room %d to itself." % [door.id, cell_room[door.a]])
			continue
		kept.append(door)
	doors = kept
	if mounts.is_empty():
		_place_default_mounts()
	if reactor_type == "core" and conduits.is_empty():
		_lay_default_conduits()


## A core ship whose file lists no conduits gets a branching network out from the AZC along the walkways:
## the cheap, fragile layout of a ship nobody designed to be easy to reroute.
func _lay_default_conduits() -> void:
	var core := Vector2i(999, 999)
	for system in systems:
		if system.id == "azc":
			core = system.cell
	if not cell_room.has(core):
		return
	var walk := {}
	for cell in cell_room:
		var list: Array[Vector2i] = []
		for step in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if cell_room.get(cell + step, -2) == cell_room[cell]:
				list.append(cell + step)
		walk[cell] = list
	for door in doors:
		if not door.to_space:
			walk[door.a].append(door.b)
			walk[door.b].append(door.a)
	var bit_for := {Vector2i(0, -1): 1, Vector2i(1, 0): 2, Vector2i(0, 1): 4, Vector2i(-1, 0): 8}
	var seen := {core: true}
	var queue: Array[Vector2i] = [core]
	conduits[core] = 0
	var reached_rooms := {cell_room[core]: true}
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for next in walk[cell]:
			if seen.has(next):
				continue
			seen[next] = true
			# One run into each room is enough; the rest of the room's tiles stay bare
			if reached_rooms.has(cell_room[next]) and cell_room[next] != cell_room[cell]:
				continue
			reached_rooms[cell_room[next]] = true
			var step: Vector2i = next - cell
			conduits[cell] = int(conduits.get(cell, 0)) | int(bit_for[step])
			conduits[next] = int(conduits.get(next, 0)) | int(bit_for[-step])
			queue.append(next)


## Ships drawn without hull art get mounts on their widest flanks, nose first (as the art rules plan hulls).
func _place_default_mounts() -> void:
	var bounds := grid_rect()
	var rows: Array[int] = []
	for row in range(bounds.position.y, bounds.end.y):
		rows.append(row)
	var picks: Array[int] = []
	if rows.size() > 0:
		picks = [rows[int(rows.size() * 0.2)], rows[int(rows.size() * 0.45)], rows[int(rows.size() * 0.7)]]
	var mount_id := 1
	for row in picks:
		var left := bounds.end.x
		var right := bounds.position.x - 1
		for cell in cell_room:
			if cell.y == row:
				left = mini(left, cell.x)
				right = maxi(right, cell.x)
		if right < left:
			continue
		mounts.append({"id": mount_id, "position": cell_centre(Vector2i(left, row)) + Vector2.LEFT * (TILE * 0.5 + 16.0), "slide": Vector2.LEFT})
		mounts.append({"id": mount_id + 1, "position": cell_centre(Vector2i(right, row)) + Vector2.RIGHT * (TILE * 0.5 + 16.0), "slide": Vector2.RIGHT})
		mount_id += 2


func cell_top_left(cell: Vector2i) -> Vector2:
	return cell_offset + Vector2(cell) * TILE


func cell_centre(cell: Vector2i) -> Vector2:
	return cell_top_left(cell) + Vector2(TILE, TILE) * 0.5


func grid_rect() -> Rect2i:
	var bounds := Rect2i()
	var first := true
	for room in rooms:
		if first:
			bounds = room.rect
			first = false
		else:
			bounds = bounds.merge(room.rect)
	return bounds


## The floor's bounding box in local pixels.
func floor_rect() -> Rect2:
	var cells := grid_rect()
	return Rect2(cell_top_left(cells.position), Vector2(cells.size) * TILE)


func system_count(system_id: String) -> int:
	var count := 0
	for system in systems:
		if system.id == system_id:
			count += 1
	return count


func mount_by_id(mount_id: int) -> Dictionary:
	for mount in mounts:
		if mount.id == mount_id:
			return mount
	return {}
