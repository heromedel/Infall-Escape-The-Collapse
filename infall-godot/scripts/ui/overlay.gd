class_name Overlay
extends Control
## A window over the ship view: a dimmed backdrop and a framed panel. Event windows, the store, the map, the
## ship screen and the menus all build on it, so they open, look and close the same way.

signal closed

var panel := PanelContainer.new()
var body := VBoxContainer.new()
var dim := ColorRect.new()


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	dim.color = Color(0.0, 0.01, 0.03, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	panel.add_theme_stylebox_override("panel", UiKit.box(Color(0.045, 0.075, 0.13, 0.97), UiColours.BORDER, 2, 6, 24))
	add_child(panel)
	body.add_theme_constant_override("separation", 12)
	panel.add_child(body)


## Centres the panel at a size; height 0 lets it grow with its contents.
func place_panel(width: float, height: float = 0.0) -> void:
	panel.custom_minimum_size = Vector2(width, height)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.resized.connect(_recentre)
	_recentre.call_deferred()


func _recentre() -> void:
	panel.position = (size - panel.size) * 0.5


func add_title(text: String, colour: Color = UiColours.TEXT) -> Label:
	var label := UiKit.title_label(text, 30, colour)
	body.add_child(label)
	return label


func add_text(text: String, size: int = 20, colour: Color = UiColours.TEXT) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.text = text
	label.add_theme_font_size_override("normal_font_size", size)
	label.add_theme_font_size_override("bold_font_size", size)
	label.add_theme_color_override("default_color", colour)
	label.custom_minimum_size = Vector2(panel.custom_minimum_size.x - 48, 0)
	body.add_child(label)
	return label


func add_separator() -> void:
	var line := ColorRect.new()
	line.color = UiColours.BORDER_DIM
	line.custom_minimum_size = Vector2(0, 1)
	body.add_child(line)


func add_button(text: String, on_press: Callable, colour: Color = UiColours.TEXT) -> Button:
	var button := UiKit.button(text, on_press)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_color_override("font_color", colour)
	button.add_theme_color_override("font_hover_color", colour.lightened(0.3))
	button.add_theme_font_size_override("font_size", 19)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(button)
	return button


func close() -> void:
	closed.emit()
	queue_free()
