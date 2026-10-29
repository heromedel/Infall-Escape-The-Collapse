## One crew skill as a small chip: its icon, its name and two pips for its level (Veteran, Master).
## Editable chips step through the levels when clicked.
class_name SkillChip
extends Control

const CHIP_SIZE := Vector2(104, 30)
## Which icon each skill uses.
const ART := {"piloting": "piloting", "engines": "engines", "shields": "shield", "weapons": "laser",
	"repair": "repair", "combat": "combat"}

signal changed(skill: String, level: int)

var skill := "piloting"
var level := 0
var editable := false
## Experience in this skill, or -1 to hide the progress bar.
var xp := -1.0
var _hover := false


func setup(skill_name: String, skill_level: int, can_edit: bool, experience: float = -1.0) -> SkillChip:
	skill = skill_name
	level = skill_level
	editable = can_edit
	xp = experience
	custom_minimum_size = CHIP_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP if editable else Control.MOUSE_FILTER_PASS
	tooltip_text = "%s: %s%s" % [CrewSkills.LABELS[skill], CrewSkills.LEVEL_NAMES[level], "\nClick to change." if editable else ""]
	if xp >= 0.0:
		tooltip_text += "\nXP %d%s" % [int(xp), "" if level >= CrewSkills.MAX_LEVEL else " / %d" % int(Battle.xp_for_level(level + 1))]
	mouse_entered.connect(func(): _hover = true; queue_redraw())
	mouse_exited.connect(func(): _hover = false; queue_redraw())
	return self


func _gui_input(event: InputEvent) -> void:
	if editable and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		level = (level + 1) % (CrewSkills.MAX_LEVEL + 1)
		tooltip_text = "%s: %s\nClick to change." % [CrewSkills.LABELS[skill], CrewSkills.LEVEL_NAMES[level]]
		Sounds.play("click")
		changed.emit(skill, level)
		queue_redraw()
		accept_event()


func _draw() -> void:
	var color := UiKit.ACCENT if level > 0 else UiKit.FAINT
	var fill := Color("#0c111d") if not _hover else Color("#18203a")
	draw_style_box(UiKit.box(fill, Color(color, 0.6 if level > 0 else 0.35), 6, 1), Rect2(Vector2.ZERO, CHIP_SIZE))
	IconPainter.paint(self, ART[skill], Vector2(15, CHIP_SIZE.y / 2.0), 17, color if level > 0 else UiKit.MUTED)
	draw_string(UiKit.body_font, Vector2(28, 19), CrewSkills.LABELS[skill], HORIZONTAL_ALIGNMENT_LEFT, 52, 12,
		UiKit.TEXT if level > 0 else UiKit.MUTED)
	if xp >= 0.0 and level < CrewSkills.MAX_LEVEL:
		# Progress toward the next level along the chip's bottom edge.
		var from := Battle.xp_for_level(level)
		var to := Battle.xp_for_level(level + 1)
		var fraction := clampf((xp - from) / maxf(1.0, to - from), 0.0, 1.0)
		draw_rect(Rect2(3, CHIP_SIZE.y - 4, (CHIP_SIZE.x - 6) * fraction, 2), UiKit.GOOD)
	for pip in CrewSkills.MAX_LEVEL:
		var center := Vector2(CHIP_SIZE.x - 18 + pip * 9, CHIP_SIZE.y / 2.0)
		if pip < level:
			draw_circle(center, 3.4, UiKit.ACCENT)
		else:
			draw_arc(center, 3.2, 0, TAU, 12, UiKit.FAINT, 1.2, true)
