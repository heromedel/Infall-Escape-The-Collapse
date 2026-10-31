## A small icon as a Control, for lists and rows.
class_name IconSwatch
extends Control

var art := "power"
var color := UiKit.GOOD
var icon_size := 20.0


func _init() -> void:
	custom_minimum_size = Vector2(24, 24)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	IconPainter.paint(self, art, size / 2.0, icon_size, color)
