class_name XmlTree
extends RefCounted
## Reads an XML file into a small tree of XmlTree nodes: a tag name, its attributes, its text and its children.
## Content files (ships, weapons, events) are read through this so the readers never touch XMLParser directly.

var tag: String = ""
var attributes: Dictionary = {}
var text: String = ""
var children: Array[XmlTree] = []


static func load_file(path: String) -> XmlTree:
	var parser := XMLParser.new()
	if parser.open(path) != OK:
		push_error("Can't open XML file: " + path)
		return null
	var root := XmlTree.new()
	root.tag = "#document"
	var stack: Array[XmlTree] = [root]
	while parser.read() == OK:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				var node := XmlTree.new()
				node.tag = parser.get_node_name()
				for i in parser.get_attribute_count():
					node.attributes[parser.get_attribute_name(i)] = parser.get_attribute_value(i)
				stack.back().children.append(node)
				if not parser.is_empty():
					stack.append(node)
			XMLParser.NODE_ELEMENT_END:
				if stack.size() > 1:
					stack.pop_back()
			XMLParser.NODE_TEXT, XMLParser.NODE_CDATA:
				stack.back().text += parser.get_node_data()
	if root.children.is_empty():
		push_error("Empty XML file: " + path)
		return null
	return root.children[0]


func get_attr(name: String, fallback: String = "") -> String:
	return attributes.get(name, fallback)


func has_attr(name: String) -> bool:
	return attributes.has(name)


func get_float(name: String, fallback: float = 0.0) -> float:
	return float(attributes[name]) if attributes.has(name) else fallback


func get_int(name: String, fallback: int = 0) -> int:
	return int(attributes[name]) if attributes.has(name) else fallback


func get_bool(name: String, fallback: bool = false) -> bool:
	if not attributes.has(name):
		return fallback
	return String(attributes[name]).to_lower() in ["yes", "true", "1", "on"]


## The tidy text of this node: whitespace runs collapsed, blank lines kept as paragraph breaks.
func get_clean_text() -> String:
	var paragraphs: PackedStringArray = []
	for block in text.strip_edges().split("\n\n"):
		var words := block.strip_edges().split("\n")
		var line := ""
		for part in words:
			var piece := part.strip_edges()
			if piece.is_empty():
				continue
			line += (" " if not line.is_empty() else "") + piece
		if not line.is_empty():
			paragraphs.append(line)
	return "\n\n".join(paragraphs)


func first(child_tag: String) -> XmlTree:
	for child in children:
		if child.tag == child_tag:
			return child
	return null


func all(child_tag: String) -> Array[XmlTree]:
	var found: Array[XmlTree] = []
	for child in children:
		if child.tag == child_tag:
			found.append(child)
	return found
