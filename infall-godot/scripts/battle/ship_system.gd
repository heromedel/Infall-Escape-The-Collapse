class_name ShipSystem
extends RefCounted
## One installed system on one ship: its level (bars), damage, ion, and the power it was given.
## How much power it actually has depends on the ship's power model, so Ship.system_power() answers that.

const ION_TICKS := 100            # one ion bar wears off every 5 s

var def: SystemDef
var behaviour: String
var label: String = ""
var level: int = 1
var damage: int = 0                # broken bars
var repair_progress: float = 0.0   # toward the next bar repaired, 0 to 100
var ion: int = 0
var ion_ticks: int = 0
var spored: bool = false           # Sporewing hit: off until cleared like a repair
var spore_progress: float = 0.0
var power: int = 0                 # bars given (reactor pool ships)
var enabled: bool = true           # switched on (core ships)
var own_power: int = 0             # bars it carries itself (Mecha ships)
var integration_bar: bool = false  # a Mecha crew member is integrated with it
var room: int = -1
var cell: Vector2i
var wall: String = "north"
var manned_by: CrewMember = null
var manned_count: int = 0


func usable_bars() -> int:
	return maxi(0, level - damage)


func is_broken() -> bool:
	return damage >= level


func is_damaged() -> bool:
	return damage > 0 or spored


func skill_name() -> String:
	match behaviour:
		"piloting", "engines", "shields", "weapons":
			return behaviour
		"sensors", "doors":
			return "repair"
	return ""


func tick_ion() -> void:
	if ion <= 0:
		return
	ion_ticks -= 1
	if ion_ticks <= 0:
		ion -= 1
		ion_ticks = ION_TICKS if ion > 0 else 0


func add_ion(amount: int) -> void:
	ion = mini(level, ion + amount)
	ion_ticks = ION_TICKS


func display_name() -> String:
	return def.name if label.is_empty() else "%s %s" % [def.name, label]
