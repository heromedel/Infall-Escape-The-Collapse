## The weapon designer: build a weapon from its parts (kind, power, shots, damage, speed, specials) and see what it
## costs and how many cards it adds. Shown over the Ship Designer; emits made(weapon) when the weapon is added.
## Once made, a weapon is fixed; to change one, remove it and make another.
class_name WeaponDesigner
extends Control

signal made(weapon: Dictionary)

const NUMBER_PARTS := [
	["power", "Power", 1, 4, 1], ["shots", "Shots", 1, 6, 1], ["damage", "Damage", 0, 4, 1],
	["speed", "Speed (cards)", 1, Weapons.MAX_SPEED, 1], ["rooms", "Systems swept", 1, 4, 1],
	["fire", "Fire %", 0, 100, 10], ["breach", "Breach %", 0, 100, 10], ["pierce", "Pierce", 0, 3, 1],
	["crewDamage", "Crew damage", 0, 4, 1],
]
const FLAG_PARTS := [["multi_target", "Multi-target"], ["chain", "Chain"], ["defensive", "Defensive"],
	["spores", "Spores"], ["stun", "Stun"], ["mind", "Mind control"]]

var _weapon := {}
var _summary: Label
var _body: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiKit.panel(Color("#0d1220"), UiKit.ACCENT, 10)
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)
	_body = UiKit.vbox(8)
	panel.add_child(UiKit.margin(_body, 16))
	_weapon = Weapons.from_attributes({"name": "New Laser", "kind": "laser"})
	_rebuild()


func _rebuild() -> void:
	for child in _body.get_children():
		child.queue_free()
	_body.add_child(UiKit.heading("DESIGN A WEAPON", 24, UiKit.ACCENT))
	var name_row := UiKit.hbox(8)
	name_row.add_child(_label("Name"))
	var name_edit := LineEdit.new()
	name_edit.text = _weapon.name
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.text_changed.connect(func(text): _weapon.name = text)
	name_row.add_child(name_edit)
	_body.add_child(name_row)

	var kind_row := UiKit.hbox(8)
	kind_row.add_child(_label("Kind"))
	var kinds := OptionButton.new()
	var kind_ids: Array = Catalog.weapon_families.keys()
	for kind_id in kind_ids:
		kinds.add_item(Catalog.weapon_family(kind_id).name)
	kinds.select(kind_ids.find(_weapon.kind))
	kinds.item_selected.connect(func(index):
		_weapon.kind = kind_ids[index]
		_update(true))
	kind_row.add_child(kinds)
	_body.add_child(kind_row)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	for part in NUMBER_PARTS:
		if part[0] == "rooms" and _weapon.kind != "beam":
			continue
		grid.add_child(_stepper(part[0], part[1], part[2], part[3], part[4]))
	_body.add_child(grid)

	var flags := HFlowContainer.new()
	for part in FLAG_PARTS:
		var box := CheckBox.new()
		box.text = part[1]
		box.button_pressed = _weapon[part[0]]
		box.toggled.connect(func(on):
			_weapon[part[0]] = on
			_update(false))
		flags.add_child(box)
	_body.add_child(flags)

	_summary = UiKit.label("", 14, UiKit.TEXT)
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(_summary)
	var buttons := UiKit.hbox(10)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_child(UiKit.button("Suggested speed", func(): _update(true), 14))
	buttons.add_child(UiKit.button("Cancel", queue_free, 16))
	buttons.add_child(UiKit.primary_button("ADD TO SHIP", func():
		_weapon.id = ""
		made.emit(_weapon.duplicate())
		queue_free(), 16))
	_body.add_child(buttons)
	_update(false)


## Recomputes price and Mawjig; with reset_speed, sets speed to the one its cooldown suggests.
func _update(reset_speed: bool) -> void:
	var rebuild := reset_speed
	_weapon = Weapons.finish(_weapon, 0 if reset_speed else int(_weapon.speed))
	if rebuild:
		_rebuild()
		return
	var suggested: int = Weapons.finish(_weapon.duplicate(), 0).speed
	_summary.text = "%s\n%d card%s in the deck (suggested %d) · price %s · %s per card" % [
		Weapons.card_text(_weapon), _weapon.speed, "" if _weapon.speed == 1 else "s", suggested,
		Money.text(_weapon.price), Money.text(_weapon.ammo)]


func _stepper(key: String, title: String, low: int, high: int, step: int) -> Control:
	var row := UiKit.hbox(4)
	var label := _label(title)
	label.custom_minimum_size.x = 120
	row.add_child(label)
	var shown := UiKit.label(str(_weapon[key]), 16, UiKit.TEXT, UiKit.display_bold_font)
	shown.custom_minimum_size = Vector2(40, 0)
	shown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var change := func(delta: int):
		_weapon[key] = clampi(int(_weapon[key]) + delta * step, low, high)
		shown.text = str(_weapon[key])
		_update(false)
	var minus := UiKit.button("−", func(): change.call(-1), 15)
	var plus := UiKit.button("+", func(): change.call(1), 15)
	row.add_child(minus)
	row.add_child(shown)
	row.add_child(plus)
	return row


func _label(text: String) -> Label:
	var label := UiKit.label(text, 14, UiKit.MUTED)
	label.custom_minimum_size.x = 60
	return label
