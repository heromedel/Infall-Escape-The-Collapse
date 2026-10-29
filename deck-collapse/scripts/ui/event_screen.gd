## An event at a beacon, in the genre's box: the opening text, then numbered choices (blue ones in blue with their
## requirement first). A choice shows its outcome and what was gained or lost, then Continue, or the outcome's own
## choices. Emits done(battle) at the end: battle is true when the event leads to a fight.
class_name EventScreen
extends Control

signal done(battle: bool)

const BLUE := Color("#5fb8ff")

var run: RunState
var _box: VBoxContainer


func _ready() -> void:
	add_child(Starfield.new())
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiKit.panel(Color(0.05, 0.07, 0.12, 0.96), Color("#3a4a72"), 10)
	panel.custom_minimum_size = Vector2(760, 0)
	center.add_child(panel)
	_box = UiKit.vbox(14)
	panel.add_child(UiKit.margin(_box, 26))
	var event: Dictionary = run.beacon.event
	_show(event.name, event.text, [], run.event_choices(event.choices), false)


## Shows a box: its text, any gains and losses, then choices or Continue.
func _show(title: String, text: String, summary: Array, choices: Array, battle: bool) -> void:
	for child in _box.get_children():
		child.queue_free()
	if title != "":
		_box.add_child(UiKit.label(title.to_upper(), 14, UiKit.MUTED, UiKit.display_font))
	var body := UiKit.label(text, 18, UiKit.TEXT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(body)
	if not summary.is_empty():
		var gains := UiKit.panel(Color("#121a2c"), UiKit.LINE, 6)
		var gains_text := UiKit.label("   ".join(summary), 16, UiKit.ACCENT, UiKit.body_bold_font)
		gains_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		gains.add_child(UiKit.margin(gains_text, 10))
		_box.add_child(gains)
	if choices.is_empty():
		_add_choice(1, "Continue...", UiKit.TEXT, func(): done.emit(battle))
		return
	var number := 1
	# Ordinary choices first, then blue ones (the genre's order).
	for shown in choices.filter(func(c): return c.choice.requires == "") + choices.filter(func(c): return c.choice.requires != ""):
		var choice: Dictionary = shown.choice
		var label: String = String(choice.text).replace("{crew}", shown.crew)
		var color := UiKit.TEXT
		if choice.requires != "":
			label = "%s %s" % [RunState.requirement_label(choice.requires), label]
			color = BLUE
		_add_choice(number, label, color, func(): _choose(choice, shown.crew))
		number += 1


func _add_choice(number: int, text: String, color: Color, action: Callable) -> void:
	var button := Button.new()
	button.text = "%d. %s" % [number, text]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.flat = true
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color.lightened(0.35))
	button.add_theme_font_size_override("font_size", 17)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(func():
		Sounds.play("click")
		action.call())
	_box.add_child(button)


func _choose(choice: Dictionary, crew_name: String) -> void:
	var result := run.resolve_event_choice(choice, crew_name)
	var follow_up := run.event_choices(result.outcome.choices)
	for shown in follow_up:
		if shown.crew == "":
			shown.crew = crew_name
	_show("", result.text, result.summary, follow_up, result.battle)
