class_name EventDef
extends RefCounted
## One event, read from content/events/*.xml in the form of events-sample.md: an opening box, numbered
## choices (blue choices carry a requirement), and outcomes that may roll between variants (1a, 1b).
## Each outcome's effects (Mawjig, crew, hull, a fight, a store...) are kept as plain tags for EventRunner.

var id: String
var title: String = ""
var kind: String = "neutral"      # store, hostile, distress, neutral, nothing, hazard, items, opening, final
var low_band: int = 1
var high_band: int = 8
var states: PackedStringArray = []   # cluster states it fits; empty is any
var races: PackedStringArray = []    # region races it fits; empty or "any" is any
var weight: float = 1.0
var unique: bool = false
var hazard: String = ""            # asteroids, sun, nebula, ion_storm, collapse_edge
var after_collapse: bool = false   # needs the collapse to be known: not during the collapse opening (GDD 2P)
var text: String = ""
var choices: Array = []            # {text, requires, outcomes: [{weight, text, effects: [{tag, attrs}]}]}


static func from_xml(node: XmlTree) -> EventDef:
	var def := EventDef.new()
	def.id = node.get_attr("id")
	def.title = node.get_attr("title", "")
	def.kind = node.get_attr("kind", "neutral")
	var bands := node.get_attr("bands", "1-8").split("-")
	def.low_band = int(bands[0])
	def.high_band = int(bands[bands.size() - 1])
	def.states = node.get_attr("states", "").split(",", false)
	def.races = node.get_attr("races", "").split(",", false)
	def.weight = node.get_float("weight", 1.0)
	def.unique = node.get_bool("unique", false)
	def.hazard = node.get_attr("hazard", "")
	def.after_collapse = node.get_bool("after_collapse", false)
	var text_node := node.first("text")
	if text_node:
		def.text = text_node.get_clean_text()
	for choice_node in node.all("choice"):
		def.choices.append(_read_choice(choice_node))
	if def.choices.is_empty():
		def.choices.append({"text": "Continue...", "requires": "", "outcomes": [{"weight": 1.0, "text": "", "effects": []}]})
	return def


static func _read_choice(node: XmlTree) -> Dictionary:
	var choice := {"text": node.get_attr("text", "Continue..."), "requires": node.get_attr("requires", ""), "outcomes": []}
	var outcome_nodes := node.all("outcome")
	if outcome_nodes.is_empty():
		choice.outcomes.append(_read_outcome(node))
	else:
		for outcome_node in outcome_nodes:
			choice.outcomes.append(_read_outcome(outcome_node))
	return choice


static func _read_outcome(node: XmlTree) -> Dictionary:
	var outcome := {"weight": node.get_float("weight", 1.0), "text": "", "effects": []}
	for child in node.children:
		if child.tag == "text":
			outcome.text = child.get_clean_text()
		elif child.tag not in ["outcome", "choice"]:
			outcome.effects.append({"tag": child.tag, "attrs": child.attributes})
	return outcome


func fits(band: int, state_list: Array, race: String) -> bool:
	if band < low_band or band > high_band:
		return false
	if not races.is_empty() and not races.has("any") and not races.has(race):
		return false
	if states.is_empty():
		return true
	for state in state_list:
		if states.has(state):
			return true
	return false
