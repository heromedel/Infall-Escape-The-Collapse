class_name RoomPicker
extends Overlay
## Picks the room a new system is installed in (GDD 5E: into a room of the player's choice, not a room reserved
## for it). Shows the ship's floor; rooms with a free tile can be clicked.

signal picked(room_index: int)

var ship: Ship
var system_name: String
var _plan := FloorPlan.new()


func open(for_ship: Ship, new_system: String) -> void:
	ship = for_ship
	system_name = new_system
	place_panel(760)
	add_title("INSTALL %s" % new_system.to_upper())
	add_text("Choose the room for it on the %s. A room can hold more than one system." % ship.name, 18, UiColours.TEXT_DIM)
	_plan.ship = ship
	_plan.custom_minimum_size = Vector2(700, 520)
	_plan.chosen.connect(func(room_index: int):
		picked.emit(room_index)
		close())
	body.add_child(_plan)
	add_button("Cancel", close)


class FloorPlan:
	extends Control
	signal chosen(room_index: int)
	var ship: Ship
	var _hover := -1

	func _scale_and_offset() -> Array:
		var floor_rect := ship.design.floor_rect()
		var fit := minf(size.x / floor_rect.size.x, size.y / floor_rect.size.y) * 0.9
		fit = minf(fit, 1.6)
		var offset := size * 0.5 - floor_rect.get_center() * fit
		return [fit, offset]

	func _room_free(room_index: int) -> bool:
		return ShipOutfitter._free_console_cell(ship, room_index) != Vector2i(999, 999)

	func _gui_input(event: InputEvent) -> void:
		var transform := _scale_and_offset()
		if event is InputEventMouseMotion:
			var local: Vector2 = (event.position - transform[1]) / transform[0]
			_hover = ship.room_at(Vector2i(floor((local - ship.design.cell_offset) / ShipDesign.TILE)))
			queue_redraw()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if _hover >= 0 and _room_free(_hover):
				Sfx.play("select")
				chosen.emit(_hover)

	func _draw() -> void:
		var transform := _scale_and_offset()
		var fit: float = transform[0]
		var offset: Vector2 = transform[1]
		for room in ship.rooms:
			var rect := Rect2(ship.design.cell_top_left(room.rect.position) * fit + offset, Vector2(room.rect.size) * ShipDesign.TILE * fit)
			var free := _room_free(room.index)
			var fill := UiColours.FLOOR if free else UiColours.UNSEEN_FLOOR
			if room.index == _hover and free:
				fill = Color("#e8f6d8")
			draw_rect(rect, fill)
			draw_rect(rect, UiColours.WALL, false, 3.0)
			for system in room.systems:
				SystemIcons.draw(self, system.def.icon, ship.design.cell_centre(system.cell) * fit + offset, 18 * fit, UiColours.POWER_GREEN)
			if room.systems.is_empty():
				UiKit.draw_text(self, rect.get_center() + Vector2(0, 5), "empty", int(12 * fit), Color(0.2, 0.25, 0.3), null, HORIZONTAL_ALIGNMENT_CENTER, 0)
			if room.index == _hover and free:
				draw_rect(rect.grow(-2), UiColours.POWER_GREEN, false, 2.5)
