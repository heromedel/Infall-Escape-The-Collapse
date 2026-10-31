class_name SystemDef
extends RefCounted
## One kind of ship system, read from content/systems/<id>/system.xml.
## `behaviour` names what the battle does with it; two systems with the same behaviour work the same way
## (the Mecha Weapon Pod behaves as Weapons, the Cybernetic Servicing Core as a Medbay).

var id: String
var name: String
var behaviour: String           # shields, engines, piloting, weapons, oxygen, medbay, sensors, doors, teleporter, supershield, evb_dock, cloaking, power_core
var max_level: int = 3
var draws_power: bool = true    # takes reactor (or core) capacity; subsystems don't
var manned: bool = false        # a crew member at its console gives a bonus
var buy_price: int = 0          # Mawjig hundredths to install at level 1
var upgrade_prices: Array[int] = []   # step prices for level 2, 3, ...
var description: String = ""
var level_notes: PackedStringArray = []
var icon: String = ""
var hotkey: String = ""
var order: int = 50             # where it sits in the power bar row


static func from_xml(node: XmlTree) -> SystemDef:
	var def := SystemDef.new()
	def.id = node.get_attr("id")
	def.name = node.get_attr("name", def.id.capitalize())
	def.behaviour = node.get_attr("behaviour", def.id)
	def.max_level = node.get_int("max_level", 3)
	def.draws_power = node.get_bool("draws_power", true)
	def.manned = node.get_bool("manned", false)
	def.buy_price = Mawjig.amount(node.get_float("buy", 0.0))
	for step in node.get_attr("upgrades", "").split(",", false):
		def.upgrade_prices.append(Mawjig.amount(float(step)))
	def.icon = node.get_attr("icon", def.behaviour)
	def.hotkey = node.get_attr("hotkey", "")
	def.order = node.get_int("order", 50)
	var description_node := node.first("description")
	if description_node:
		def.description = description_node.get_clean_text()
	for level_node in node.all("level"):
		def.level_notes.append(level_node.get_clean_text())
	return def


## The price of the step from `level` to `level + 1`, or -1 when the system is at its top level.
func upgrade_price(level: int) -> int:
	var index := level - 1
	if index < 0 or index >= upgrade_prices.size() or level >= max_level:
		return -1
	return upgrade_prices[index]


func level_note(level: int) -> String:
	if level >= 1 and level <= level_notes.size():
		return level_notes[level - 1]
	return ""
