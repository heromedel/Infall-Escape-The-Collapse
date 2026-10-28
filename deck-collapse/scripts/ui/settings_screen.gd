## Settings: each one shows its current choice; click to step to the next. Defaults are listed first.
class_name SettingsScreen
extends Control

signal back

var _rows: VBoxContainer


func _ready() -> void:
	add_child(Starfield.new())
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiKit.panel(Color(0.06, 0.08, 0.13, 0.94))
	panel.custom_minimum_size = Vector2(860, 0)
	center.add_child(panel)
	var box := UiKit.vbox(12)
	panel.add_child(UiKit.margin(box, 14))
	var top := UiKit.hbox(12)
	top.add_child(UiKit.button("‹ Back", func(): back.emit(), 17))
	var title := UiKit.heading("SETTINGS", 32)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	top.add_child(UiKit.button("Reset to Defaults", _reset, 15))
	box.add_child(top)
	box.add_child(UiKit.label("Defaults follow the design document. Click a value to change it.", 14, UiKit.MUTED))
	_rows = UiKit.vbox(6)
	box.add_child(_rows)
	_rebuild()


func _rebuild() -> void:
	for child in _rows.get_children():
		child.queue_free()
	for key in Settings.OPTIONS:
		var option: Dictionary = Settings.OPTIONS[key]
		var row := UiKit.hbox(14)
		var text := UiKit.vbox(0)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_child(UiKit.label(option.label, 17, UiKit.TEXT, UiKit.display_font))
		var help := UiKit.label(option.help, 13, UiKit.MUTED)
		help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_child(help)
		row.add_child(text)
		var value := Settings.value(key)
		var is_default: bool = value == option.choices[0]
		var choices_text := " > ".join(option.choices)
		var button := UiKit.button(value + ("" if is_default else "  •"), func():
			Settings.cycle(key)
			_rebuild(), 16, 190)
		button.tooltip_text = "Choices (default first): " + choices_text
		if not is_default:
			button.add_theme_color_override("font_color", UiKit.ACCENT)
		row.add_child(button)
		_rows.add_child(row)


func _reset() -> void:
	for key in Settings.OPTIONS:
		Settings.set_value(key, Settings.OPTIONS[key].choices[0])
	_rebuild()
